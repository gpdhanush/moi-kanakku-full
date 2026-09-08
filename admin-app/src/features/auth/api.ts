import { apiClient } from '@/lib/axios';
import { secureStorageWithCache } from '@/lib/secureStorage';
import type { AxiosError } from 'axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | string;
  responseValue: T;
  responseMessage?: string;
}

export interface AdminUser {
  status: string;
  id: string;
  name: string;
  mobile: string;
  email: string;
  last_login: string;
  profile_image: string | null;
  token: string;
}

export interface LoginResult {
  mfaRequired: false;
  token: string;
  user: Omit<AdminUser, 'token'>;
}

export interface MfaChallengeResult {
  mfaRequired: true;
  userId: string;
  accountType: string;
  message?: string;
}

export type AdminLoginResult = LoginResult | MfaChallengeResult;

export interface LoginErrorPayload {
  message?: string;
  attempts_remaining?: number;
  blocked_until?: string;
  [key: string]: unknown;
}

export class AuthLoginError extends Error {
  status: number;
  attemptsRemaining?: number;
  blockedUntil?: string | null;
  payload?: LoginErrorPayload | string;

  constructor(options: {
    message: string;
    status: number;
    attemptsRemaining?: number;
    blockedUntil?: string | null;
    payload?: LoginErrorPayload | string;
  }) {
    super(options.message);
    this.name = 'AuthLoginError';
    this.status = options.status;
    this.attemptsRemaining = options.attemptsRemaining;
    this.blockedUntil = options.blockedUntil ?? null;
    this.payload = options.payload;
  }
}

type LoginApiUser = {
  id?: string | number;
  user_id?: string | number;
  full_name?: string;
  name?: string;
  email?: string;
  mobile?: string;
  status?: string;
  last_login_at?: string;
  last_login?: string;
  profile_image?: string | null;
  token?: string;
  mfa_required?: boolean;
  is_mfa_required?: boolean;
  account_type?: string;
  accountType?: string;
  message?: string;
};

function extractMessage(
  data: MoiApiResponse<unknown> | undefined,
  fallback: string
): string {
  if (!data) return fallback;
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message || fallback);
  }
  if (typeof value === 'string' && value.trim()) return value;
  if (data.responseMessage) return data.responseMessage;
  return fallback;
}

function normalizeUser(value: LoginApiUser): AdminUser {
  const token = value.token || '';
  return {
    id: String(value.id ?? ''),
    name: value.full_name || value.name || 'Admin',
    email: value.email || '',
    mobile: value.mobile || '',
    status: value.status || 'ACTIVE',
    last_login: value.last_login_at || value.last_login || '',
    profile_image: value.profile_image ?? null,
    token,
  };
}

function toLoginError(error: unknown): AuthLoginError {
  const axiosError = error as AxiosError<MoiApiResponse<LoginErrorPayload | string>>;
  const status = axiosError.response?.status ?? 0;
  const data = axiosError.response?.data;
  const payload = data?.responseValue;
  const objectPayload =
    payload && typeof payload === 'object' ? (payload as LoginErrorPayload) : undefined;

  const attemptsRemaining =
    typeof objectPayload?.attempts_remaining === 'number'
      ? objectPayload.attempts_remaining
      : undefined;
  const blockedUntil =
    typeof objectPayload?.blocked_until === 'string'
      ? objectPayload.blocked_until
      : null;

  let fallback = 'Unable to sign in. Please try again.';
  if (status === 401) fallback = 'Invalid identifier or password.';
  if (status === 403) {
    fallback =
      'This admin account is inactive or deleted. Please contact system support.';
  }
  if (status === 429) {
    fallback = 'Too many failed attempts. Your account is temporarily locked.';
  }

  return new AuthLoginError({
    message: extractMessage(data, fallback),
    status,
    attemptsRemaining,
    blockedUntil,
    payload,
  });
}

export const authApi = {
  login: async (
    identifier: string,
    password: string
  ): Promise<AdminLoginResult> => {
    try {
      const response = await apiClient.post<MoiApiResponse<LoginApiUser>>(
        '/users/admin/login',
        {
          identifier: identifier.trim(),
          password,
        },
        {
          skipLoading: true,
          skipErrorHandler: true,
        }
      );

      const data = response.data;
      if (String(data.responseType).toUpperCase() !== 'S') {
        throw new AuthLoginError({
          message: extractMessage(data, 'Login failed'),
          status: response.status || 400,
          payload: data.responseValue as LoginErrorPayload | string,
        });
      }

      const value = data.responseValue || {};
      const mfaRequired = Boolean(
        value.mfa_required ?? value.is_mfa_required
      );

      if (mfaRequired) {
        const userId = String(value.user_id ?? value.id ?? '');
        if (!userId) {
          throw new AuthLoginError({
            message: 'MFA challenge returned without a user id',
            status: 500,
          });
        }
        return {
          mfaRequired: true,
          userId,
          accountType: String(value.account_type || value.accountType || 'admin'),
          message: value.message,
        };
      }

      const user = normalizeUser(value);
      if (!user.token) {
        throw new AuthLoginError({
          message: 'Login succeeded but no token was returned',
          status: 500,
        });
      }

      const { token, ...rest } = user;
      return { mfaRequired: false, token, user: rest };
    } catch (error) {
      if (error instanceof AuthLoginError) throw error;
      throw toLoginError(error);
    }
  },

  logout: async (): Promise<void> => {
    await secureStorageWithCache.removeItem('auth_token');
    await secureStorageWithCache.removeItem('user');
    await secureStorageWithCache.removeItem('remember_me');
  },

  forgotPassword: async (identifier: string): Promise<{ message: string }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{ message?: string } | string>
      >(
        '/users/admin/forgot-password',
        { identifier: identifier.trim() },
        { skipLoading: true, skipErrorHandler: true }
      );
      const data = response.data;
      if (String(data.responseType).toUpperCase() !== 'S') {
        throw new Error(extractMessage(data, 'Failed to send reset email'));
      }
      const value = data.responseValue;
      const message =
        value && typeof value === 'object' && 'message' in value
          ? String(value.message)
          : typeof value === 'string'
            ? value
            : 'Password reset details were sent to your email.';
      return { message };
    } catch (error) {
      if (error instanceof Error && !(error as AxiosError).isAxiosError) {
        throw error;
      }
      const axiosError = error as AxiosError<MoiApiResponse<unknown>>;
      throw new Error(
        extractMessage(
          axiosError.response?.data,
          axiosError.message || 'Failed to send reset email'
        )
      );
    }
  },

  resetPassword: async (
    token: string,
    password: string
  ): Promise<{ message: string }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{ message?: string } | string>
      >(
        '/users/admin/reset-password',
        { token, password },
        { skipLoading: true, skipErrorHandler: true }
      );
      const data = response.data;
      if (String(data.responseType).toUpperCase() !== 'S') {
        throw new Error(extractMessage(data, 'Failed to reset password'));
      }
      const value = data.responseValue;
      const message =
        value && typeof value === 'object' && 'message' in value
          ? String(value.message)
          : typeof value === 'string'
            ? value
            : 'Password changed successfully.';
      return { message };
    } catch (error) {
      if (error instanceof Error && !(error as AxiosError).isAxiosError) {
        throw error;
      }
      const axiosError = error as AxiosError<MoiApiResponse<unknown>>;
      throw new Error(
        extractMessage(
          axiosError.response?.data,
          axiosError.message || 'Failed to reset password'
        )
      );
    }
  },

  updateProfile: async (payload: {
    full_name: string;
    email: string;
    mobile: string;
  }): Promise<Omit<AdminUser, 'token'>> => {
    try {
      const response = await apiClient.post<MoiApiResponse<LoginApiUser>>(
        '/users/admin/update-profile',
        {
          full_name: payload.full_name.trim(),
          email: payload.email.trim(),
          mobile: payload.mobile.trim(),
        },
        { skipErrorHandler: true }
      );
      const data = response.data;
      if (String(data.responseType).toUpperCase() !== 'S') {
        throw new Error(extractMessage(data, 'Failed to update profile'));
      }

      const current = await secureStorageWithCache.getItem('user');
      let existing: Partial<Omit<AdminUser, 'token'>> = {};
      if (current) {
        try {
          existing = JSON.parse(current);
        } catch {
          existing = {};
        }
      }

      const raw = data.responseValue || {};
      const updated = normalizeUser({
        ...existing,
        ...raw,
        token: '',
      });
      const { token: _token, ...user } = updated;

      await secureStorageWithCache.setItem('user', JSON.stringify(user));
      if (typeof window !== 'undefined') {
        window.dispatchEvent(new Event('moi-admin-user-updated'));
      }

      return user;
    } catch (error) {
      if (error instanceof Error && !(error as AxiosError).isAxiosError) {
        throw error;
      }
      const axiosError = error as AxiosError<MoiApiResponse<unknown>>;
      throw new Error(
        extractMessage(
          axiosError.response?.data,
          axiosError.message || 'Failed to update profile'
        )
      );
    }
  },

  changePassword: async (payload: {
    current_password: string;
    new_password: string;
  }): Promise<{ message: string }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{ message?: string } | string>
      >(
        '/users/admin/change-password',
        {
          current_password: payload.current_password,
          new_password: payload.new_password,
        },
        { skipErrorHandler: true }
      );
      const data = response.data;
      if (String(data.responseType).toUpperCase() !== 'S') {
        throw new Error(extractMessage(data, 'Failed to change password'));
      }
      const value = data.responseValue;
      const message =
        value && typeof value === 'object' && 'message' in value
          ? String(value.message)
          : typeof value === 'string'
            ? value
            : 'Password changed successfully.';
      return { message };
    } catch (error) {
      if (error instanceof Error && !(error as AxiosError).isAxiosError) {
        throw error;
      }
      const axiosError = error as AxiosError<MoiApiResponse<unknown>>;
      throw new Error(
        extractMessage(
          axiosError.response?.data,
          axiosError.message || 'Failed to change password'
        )
      );
    }
  },
};

export interface MfaSetupResult {
  secret: string;
  qrCode: string;
  backupCodes: string[];
  manualEntryKey?: string;
  otpauthUrl?: string;
}

export interface MfaStatus {
  mfaEnabled: boolean;
  mfaRequired: boolean;
  enforcedByAdmin: boolean;
  mfaVerifiedAt: string | null;
  role?: string;
  backupCodesCount?: number;
}

export interface MfaVerifyLoginResult {
  token: string;
  accessToken?: string;
  refreshToken?: string;
  user: Omit<AdminUser, 'token'>;
  expiresIn?: number;
}

function unwrapMoiOrDirect<T>(data: unknown, fallbackMessage: string): T {
  if (data && typeof data === 'object' && 'responseType' in data) {
    const moi = data as MoiApiResponse<T>;
    if (String(moi.responseType).toUpperCase() !== 'S') {
      throw new Error(extractMessage(moi, fallbackMessage));
    }
    return moi.responseValue;
  }
  return data as T;
}

function getAxiosErrorMessage(error: unknown, fallback: string): string {
  const axiosError = error as AxiosError<MoiApiResponse<unknown> | { error?: string; message?: string }>;
  const data = axiosError.response?.data;
  if (data && typeof data === 'object') {
    if ('responseType' in data) {
      return extractMessage(data as MoiApiResponse<unknown>, fallback);
    }
    const plain = data as { error?: string; message?: string };
    if (plain.error) return plain.error;
    if (plain.message) return plain.message;
  }
  if (error instanceof Error && error.message) return error.message;
  return fallback;
}

export const mfaApi = {
  setup: async (): Promise<MfaSetupResult> => {
    try {
      const response = await apiClient.post('/mfa/setup', undefined, {
        skipErrorHandler: true,
      });
      const value = unwrapMoiOrDirect<MfaSetupResult | Record<string, unknown>>(
        response.data,
        'Failed to start MFA setup'
      );
      const raw = (value || {}) as Record<string, unknown>;
      const secret = String(raw.secret || raw.manualEntryKey || '');
      const qrCode = String(raw.qrCode || raw.qr_code || '');
      const otpauthUrl = String(raw.otpauth_url || raw.otpauthUrl || '');
      const backupCodes = Array.isArray(raw.backupCodes)
        ? (raw.backupCodes as string[])
        : Array.isArray(raw.backup_codes)
          ? (raw.backup_codes as string[])
          : [];

      if (!secret || (!qrCode && !otpauthUrl)) {
        throw new Error('MFA setup response was incomplete');
      }

      return {
        secret,
        qrCode,
        backupCodes,
        manualEntryKey: String(raw.manualEntryKey || secret),
        otpauthUrl: otpauthUrl || undefined,
      };
    } catch (error) {
      throw new Error(getAxiosErrorMessage(error, 'Failed to start MFA setup'));
    }
  },

  verifySetup: async (
    code: string,
    secret?: string
  ): Promise<{ message?: string }> => {
    try {
      // MOI backend expects `token` (not `code`)
      const response = await apiClient.post(
        '/mfa/verify-setup',
        {
          token: String(code).trim(),
          ...(secret ? { secret } : {}),
        },
        { skipErrorHandler: true }
      );
      const value = unwrapMoiOrDirect<{ success?: boolean; message?: string }>(
        response.data,
        'Failed to verify MFA setup'
      );
      return value || { message: 'MFA has been enabled successfully' };
    } catch (error) {
      throw new Error(getAxiosErrorMessage(error, 'Invalid verification code'));
    }
  },

  verify: async (
    userId: string | number,
    code: string,
    backupCode?: string,
    accountType: string = 'admin'
  ): Promise<MfaVerifyLoginResult> => {
    try {
      const token = String(code || backupCode || '').trim();
      const response = await apiClient.post(
        '/mfa/verify',
        {
          userId,
          token,
          accountType,
        },
        { skipErrorHandler: true, skipLoading: true }
      );
      const value = unwrapMoiOrDirect<Record<string, unknown>>(
        response.data,
        'MFA verification failed'
      );
      const accessToken = String(value.accessToken || value.token || '');
      if (!accessToken) {
        throw new Error('MFA verification succeeded but no token was returned');
      }

      // Backend now returns the full admin session object alongside token.
      const userRaw = (
        value.user && typeof value.user === 'object'
          ? value.user
          : value
      ) as LoginApiUser;
      const user = normalizeUser({ ...userRaw, token: accessToken });
      const { token: _t, ...rest } = user;

      return {
        token: accessToken,
        accessToken: value.accessToken ? String(value.accessToken) : undefined,
        refreshToken: value.refreshToken
          ? String(value.refreshToken)
          : undefined,
        user: rest,
        expiresIn:
          typeof value.expiresIn === 'number' ? value.expiresIn : undefined,
      };
    } catch (error) {
      throw new Error(getAxiosErrorMessage(error, 'MFA verification failed'));
    }
  },

  disable: async (totpToken?: string): Promise<{ message?: string }> => {
    try {
      const response = await apiClient.post(
        '/mfa/disable',
        totpToken ? { token: String(totpToken).trim() } : {},
        { skipErrorHandler: true }
      );
      const value = unwrapMoiOrDirect<{ message?: string }>(
        response.data,
        'Failed to disable MFA'
      );
      return value || { message: 'MFA has been disabled successfully' };
    } catch (error) {
      throw new Error(getAxiosErrorMessage(error, 'Failed to disable MFA'));
    }
  },

  getStatus: async (): Promise<MfaStatus> => {
    try {
      const response = await apiClient.get('/mfa/status', {
        skipErrorHandler: true,
      });
      const value = unwrapMoiOrDirect<Record<string, unknown>>(
        response.data,
        'Failed to load MFA status'
      );
      return {
        mfaEnabled: Boolean(
          value.mfaEnabled ?? value.mfa_enabled ?? value.is_mfa_enabled
        ),
        mfaRequired: Boolean(value.mfaRequired ?? value.mfa_required),
        enforcedByAdmin: Boolean(value.enforcedByAdmin ?? value.enforced_by_admin),
        mfaVerifiedAt:
          (value.mfaVerifiedAt as string | null | undefined) ??
          (value.mfa_verified_at as string | null | undefined) ??
          null,
        role: value.role ? String(value.role) : undefined,
        backupCodesCount:
          typeof value.backup_codes_count === 'number'
            ? value.backup_codes_count
            : typeof value.backupCodesCount === 'number'
              ? value.backupCodesCount
              : undefined,
      };
    } catch (error) {
      throw new Error(getAxiosErrorMessage(error, 'Failed to load MFA status'));
    }
  },

  regenerateBackupCodes: async (): Promise<{ backupCodes: string[] }> => {
    try {
      const response = await apiClient.post(
        '/mfa/regenerate-backup-codes',
        undefined,
        { skipErrorHandler: true }
      );
      const value = unwrapMoiOrDirect<Record<string, unknown>>(
        response.data,
        'Failed to regenerate backup codes'
      );
      const backupCodes = Array.isArray(value.backupCodes)
        ? (value.backupCodes as string[])
        : Array.isArray(value.backup_codes)
          ? (value.backup_codes as string[])
          : [];
      return { backupCodes };
    } catch (error) {
      throw new Error(
        getAxiosErrorMessage(error, 'Failed to regenerate backup codes')
      );
    }
  },
};
