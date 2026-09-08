/**
 * Centralized Configuration
 */

export const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_URL,
  SERVER_URL: (() => {
    const apiUrl = import.meta.env.VITE_API_URL || '';
    let url = apiUrl.replace(/\/$/, '');
    if (url.endsWith('/apis')) {
      url = url.slice(0, -5);
    } else if (url.endsWith('/api')) {
      url = url.slice(0, -4);
    }
    return url;
  })(),
} as const;

export const STATIC_CONFIG = {
  BASE_URL: API_CONFIG.SERVER_URL,
} as const;

export const ENV_CONFIG = {
  IS_DEV: import.meta.env.DEV || import.meta.env.MODE === 'development',
  IS_PROD: import.meta.env.PROD || import.meta.env.MODE === 'production',
  APP_VERSION: import.meta.env.VITE_APP_VERSION || '1.0.0',
  COMPANY_NAME: import.meta.env.VITE_COMPANY_NAME || 'Moi Kanakku Admin',
} as const;

/** Optional — kept for leftover EMS modules; not required for MOI Admin */
export const FIREBASE_CONFIG = {
  API_KEY: import.meta.env.VITE_FIREBASE_API_KEY,
  AUTH_DOMAIN: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  PROJECT_ID: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  STORAGE_BUCKET: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  MESSAGING_SENDER_ID: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  APP_ID: import.meta.env.VITE_FIREBASE_APP_ID,
  MEASUREMENT_ID: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
  VAPID_KEY: import.meta.env.VITE_FIREBASE_VAPID_KEY,
} as const;

export function validateConfig() {
  if (!API_CONFIG.BASE_URL) {
    if (ENV_CONFIG.IS_PROD) {
      throw new Error('Missing required environment variable: VITE_API_URL');
    }
    console.warn('⚠️  VITE_API_URL not set in .env file');
  }

  if (ENV_CONFIG.IS_PROD && API_CONFIG.BASE_URL && !API_CONFIG.BASE_URL.startsWith('https://')) {
    throw new Error('Security Error: API URL must use HTTPS in production.');
  }

  return true;
}

if (ENV_CONFIG.IS_PROD) {
  validateConfig();
}
