import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios';
import { API_CONFIG } from './config';
import { logger } from './logger';
import { forceLogout, getCsrfToken, persistAdminSession, setCsrfToken } from './auth';
import { handleApiError } from './errorHandler';
import { startApiLoading, stopApiLoading } from './apiLoading';

declare module 'axios' {
  export interface AxiosRequestConfig {
    skipLoading?: boolean;
    skipErrorHandler?: boolean;
    _retry?: boolean;
  }
}

type RequestConfigWithLoading = InternalAxiosRequestConfig & {
  skipLoading?: boolean;
  skipErrorHandler?: boolean;
  _loadingStarted?: boolean;
  _retry?: boolean;
};

const AUTH_FREE_PATHS = [
  '/users/admin/login',
  '/users/admin/refresh',
  '/users/admin/forgot-password',
  '/users/admin/reset-password',
];

function isAuthFreeRequest(config?: InternalAxiosRequestConfig): boolean {
  const url = config?.url || '';
  return AUTH_FREE_PATHS.some((path) => url.includes(path));
}

function isAdminLoginRequest(config?: InternalAxiosRequestConfig): boolean {
  const url = config?.url || '';
  return url.includes('/users/admin/login');
}

let refreshPromise: Promise<void> | null = null;

/**
 * Rotate admin session using HttpOnly refresh cookie (no token in JS storage).
 */
async function refreshAccessToken(): Promise<void> {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    const response = await axios.post(
      `${API_CONFIG.BASE_URL}/users/admin/refresh`,
      {},
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000,
        withCredentials: true,
      }
    );

    const data = response.data as {
      responseType?: string;
      responseValue?: {
        csrfToken?: string;
        id?: string | number;
        name?: string;
        full_name?: string;
        email?: string;
        [key: string]: unknown;
      };
    };

    if (String(data?.responseType || '').toUpperCase() !== 'S') {
      throw new Error('Refresh failed');
    }

    const value = data.responseValue || {};
    if (value.csrfToken) {
      setCsrfToken(String(value.csrfToken));
    }
    if (value.id != null) {
      await persistAdminSession({
        user: value,
        csrfToken: value.csrfToken ? String(value.csrfToken) : null,
      });
    }
  })().finally(() => {
    refreshPromise = null;
  });

  return refreshPromise;
}

export const apiClient = axios.create({
  baseURL: API_CONFIG.BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000,
  withCredentials: true,
});

apiClient.interceptors.request.use(
  async (config: RequestConfigWithLoading) => {
    if (!config.skipLoading) {
      startApiLoading();
      config._loadingStarted = true;
    }

    // Cookie session: never attach Authorization Bearer from localStorage.
    if (config.headers) {
      delete config.headers.Authorization;
    }

    const method = String(config.method || 'get').toUpperCase();
    const needsCsrf = !['GET', 'HEAD', 'OPTIONS'].includes(method);
    if (needsCsrf && !isAuthFreeRequest(config)) {
      const csrf = getCsrfToken();
      if (csrf) {
        config.headers['X-CSRF-Token'] = csrf;
      }
    }

    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    }

    return config;
  },
  (error: AxiosError) => {
    logger.error('Request interceptor error:', error);
    stopApiLoading();
    return Promise.reject(error);
  }
);

apiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    const config = response.config as RequestConfigWithLoading;
    if (config._loadingStarted) {
      stopApiLoading();
    }
    return response;
  },
  async (error: AxiosError) => {
    const config = error.config as RequestConfigWithLoading | undefined;
    if (config?._loadingStarted) {
      stopApiLoading();
    }

    const skipHandler = Boolean(config?.skipErrorHandler) || isAdminLoginRequest(config);
    const status = error.response?.status;

    if (status === 401 && config && !isAuthFreeRequest(config) && !config._retry) {
      try {
        await refreshAccessToken();
        config._retry = true;
        return apiClient(config);
      } catch (refreshError) {
        logger.warn('Admin token refresh failed');
      }
    }

    // Never force-logout on failed admin login attempts.
    if (status === 401 && !isAdminLoginRequest(config)) {
      const errorData = error.response?.data as {
        error?: string;
        message?: string;
        responseMessage?: string;
      };
      const errorMessage =
        errorData?.error || errorData?.message || errorData?.responseMessage || '';
      if (!skipHandler) {
        handleApiError(error, {
          title: 'Unauthorized',
          description: 'Your session has expired. Please login again.',
        });
      }
      await forceLogout(errorMessage);
    } else if (!skipHandler) {
      handleApiError(error);
    }

    return Promise.reject(error);
  }
);

export default apiClient;
