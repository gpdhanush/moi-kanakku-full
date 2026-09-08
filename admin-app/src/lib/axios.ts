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
  }
}

type RequestConfigWithLoading = InternalAxiosRequestConfig & {
  skipLoading?: boolean;
  skipErrorHandler?: boolean;
  _loadingStarted?: boolean;
};

function isAdminLoginRequest(config?: InternalAxiosRequestConfig): boolean {
  const url = config?.url || '';
  return url.includes('/users/admin/login');
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

    let token = getItemSync('auth_token');
    if (!token) {
      token = await secureStorageWithCache.getItem('auth_token');
    }

    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
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
