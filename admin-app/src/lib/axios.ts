import axios, {
  AxiosError,
  AxiosHeaders,
  AxiosResponse,
  InternalAxiosRequestConfig,
} from 'axios';
import { API_CONFIG } from './config';
import { logger } from './logger';
import {
  forceLogout,
  getAuthToken,
  getCsrfToken,
  getRefreshToken,
  persistAdminSession,
  setCsrfToken,
} from './auth';
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

/** 401 here means "not logged in" — never hard-redirect /login (causes blink loops). */
const NO_FORCE_LOGOUT_PATHS = [
  ...AUTH_FREE_PATHS,
  '/users/admin/session',
  '/users/admin/logout',
];

function isAuthFreeRequest(config?: InternalAxiosRequestConfig): boolean {
  const url = config?.url || '';
  return AUTH_FREE_PATHS.some((path) => url.includes(path));
}

function isAdminLoginRequest(config?: InternalAxiosRequestConfig): boolean {
  const url = config?.url || '';
  return url.includes('/users/admin/login');
}

function shouldSkipForceLogout(config?: InternalAxiosRequestConfig): boolean {
  const url = config?.url || '';
  return NO_FORCE_LOGOUT_PATHS.some((path) => url.includes(path));
}

let refreshPromise: Promise<void> | null = null;

/**
 * Rotate session via refresh cookie and/or in-memory / sessionStorage refresh JWT.
 */
async function refreshAccessToken(): Promise<void> {
  if (refreshPromise) return refreshPromise;

  refreshPromise = (async () => {
    const refreshToken = getRefreshToken();
    if (!refreshToken) {
      // Last resort: cookie-only refresh (same-site deployments).
    }

    const response = await axios.post(
      `${API_CONFIG.BASE_URL}/users/admin/refresh`,
      refreshToken ? { refreshToken } : {},
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
        accessToken?: string;
        token?: string;
        refreshToken?: string;
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
    const access = value.accessToken || value.token;
    if (!access) {
      throw new Error('Refresh returned no access token');
    }

    await persistAdminSession({
      user: value,
      csrfToken: value.csrfToken ? String(value.csrfToken) : null,
      accessToken: String(access),
      refreshToken: value.refreshToken
        ? String(value.refreshToken)
        : refreshToken,
    });
    if (value.csrfToken) {
      setCsrfToken(String(value.csrfToken));
    }

    // Keep proactive refresh schedule in sync after rotation.
    try {
      const { scheduleAccessTokenRefresh } = await import('./sessionKeepAlive');
      scheduleAccessTokenRefresh();
    } catch {
      // ignore circular/bootstrap timing
    }
  })().finally(() => {
    refreshPromise = null;
  });

  return refreshPromise;
}

/**
 * Ensure we have a usable access token (refresh if missing/expiring).
 * @param forceRefresh always hit /refresh
 */
export async function ensureFreshAccessToken(
  forceRefresh = false
): Promise<string | null> {
  const { isAccessTokenExpiringSoon } = await import('./jwtExpiry');
  const current = getAuthToken();
  if (!forceRefresh && current && !isAccessTokenExpiringSoon(current)) {
    return current;
  }
  // Anonymous: no memory/session refresh — skip (avoids /refresh spam on /login).
  // Soft reload overnight still has tab-scoped refresh in sessionStorage.
  if (!getRefreshToken() && !current) {
    return null;
  }
  await refreshAccessToken();
  return getAuthToken();
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

    if (!isAuthFreeRequest(config)) {
      const token = getAuthToken();
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      } else if (config.headers) {
        delete config.headers.Authorization;
      }
    } else if (config.headers) {
      delete config.headers.Authorization;
    }

    const method = String(config.method || 'get').toUpperCase();
    const needsCsrf = !['GET', 'HEAD', 'OPTIONS'].includes(method);
    // CSRF only required for cookie-authenticated mutating calls; Bearer skips it.
    if (needsCsrf && !isAuthFreeRequest(config) && !getAuthToken()) {
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

    const canTryRefresh =
      status === 401 &&
      config &&
      !isAuthFreeRequest(config) &&
      !shouldSkipForceLogout(config) &&
      !config._retry;

    if (canTryRefresh) {
      try {
        await refreshAccessToken();
        config._retry = true;
        const token = getAuthToken();
        if (token) {
          const headers = AxiosHeaders.from(config.headers ?? {});
          headers.set('Authorization', `Bearer ${token}`);
          config.headers = headers;
        }
        return apiClient(config);
      } catch {
        logger.warn('Admin token refresh failed');
      }
    }

    if (status === 401 && !shouldSkipForceLogout(config)) {
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
