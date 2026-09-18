import axios, { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from 'axios';
import { API_CONFIG } from './config';
import { secureStorageWithCache, getItemSync } from './secureStorage';
import { logger } from './logger';
import { forceLogout } from './auth';
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

let refreshPromise: Promise<string> | null = null;

async function persistTokens(accessToken: string, refreshToken?: string) {
  await secureStorageWithCache.setItem('auth_token', accessToken);
  if (refreshToken) {
    await secureStorageWithCache.setItem('refresh_token', refreshToken);
  }
}

async function refreshAccessToken(): Promise<string> {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    let refreshToken = getItemSync('refresh_token');
    if (!refreshToken) {
      refreshToken = await secureStorageWithCache.getItem('refresh_token');
    }
    if (!refreshToken) {
      throw new Error('No refresh token');
    }

    const response = await axios.post(
      `${API_CONFIG.BASE_URL}/users/admin/refresh`,
      { refreshToken },
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000,
      }
    );

    const data = response.data as {
      responseType?: string;
      responseValue?: {
        token?: string;
        accessToken?: string;
        refreshToken?: string;
      };
    };

    if (String(data?.responseType || '').toUpperCase() !== 'S') {
      throw new Error('Refresh failed');
    }

    const value = data.responseValue || {};
    const accessToken = String(value.accessToken || value.token || '');
    if (!accessToken) {
      throw new Error('Refresh returned no access token');
    }

    await persistTokens(accessToken, value.refreshToken);
    return accessToken;
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
});

apiClient.interceptors.request.use(
  async (config: RequestConfigWithLoading) => {
    if (!config.skipLoading) {
      startApiLoading();
      config._loadingStarted = true;
    }

    if (!isAuthFreeRequest(config)) {
      let token = getItemSync('auth_token');
      if (!token) {
        token = await secureStorageWithCache.getItem('auth_token');
      }

      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    } else if (config.headers) {
      delete config.headers.Authorization;
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
        const newToken = await refreshAccessToken();
        config._retry = true;
        config.headers = config.headers || {};
        config.headers.Authorization = `Bearer ${newToken}`;
        return apiClient(config);
      } catch (refreshError) {
        logger.warn('Admin token refresh failed', refreshError);
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
