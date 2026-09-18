import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
}

export type BulkEmailType = 'notification' | 'announcement' | 'custom';

export interface SendBulkEmailPayload {
  userIds: string[];
  subject: string;
  body: string;
  type: BulkEmailType;
}

export type BulkNotificationType =
  | 'moi'
  | 'moiOut'
  | 'function'
  | 'account'
  | 'settings'
  | 'general';

export interface SendBulkNotificationPayload {
  userIds: string[];
  title: string;
  body: string;
  type?: BulkNotificationType | '';
}

export interface BulkSendResult {
  message: string;
  totalRequested?: number;
  usersFound?: number;
  successful?: number;
  failed?: number;
  noDeviceToken?: number;
  failedUsers?: unknown[];
  successfulUsers?: Array<{ userId: string; email?: string }>;
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (data.responseType !== 'S') {
    throw new Error(extractErrorMessage(data));
  }
  return data.responseValue;
}

const BULK_SEND_TIMEOUT_MS = 5 * 60 * 1000;

export const emailApi = {
  sendBulk: async (payload: SendBulkEmailPayload): Promise<BulkSendResult> => {
    const response = await apiClient.post<MoiApiResponse<BulkSendResult>>(
      '/email/admin/send-bulk',
      payload,
      {
        timeout: BULK_SEND_TIMEOUT_MS,
        skipErrorHandler: true,
      }
    );
    return assertSuccess(response.data);
  },

  sendVerifyEmail: async (
    userId: string
  ): Promise<{
    message?: string;
    sent_to?: string;
    expires_in_hours?: number;
    sent?: boolean;
    queued?: boolean;
  }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{
          message?: string;
          sent_to?: string;
          expires_in_hours?: number;
          sent?: boolean;
          queued?: boolean;
        }>
      >(
        '/email/admin/send-verify-email',
        { userId: String(userId) },
        {
          // SMTP on cPanel can take longer than the default 30s.
          timeout: 60000,
          skipErrorHandler: true,
        }
      );
      return assertSuccess(response.data);
    } catch (error) {
      if (error && typeof error === 'object' && 'response' in error) {
        const data = (error as { response?: { data?: MoiApiResponse<unknown> } })
          .response?.data;
        if (data) {
          const value = data.responseValue;
          if (value && typeof value === 'object' && 'message' in value) {
            throw new Error(String((value as { message: string }).message));
          }
          if (typeof value === 'string') throw new Error(value);
          throw new Error(data.responseMessage || 'Failed to send verification email');
        }
      }
      if (error instanceof Error) {
        if (/timeout/i.test(error.message)) {
          throw new Error(
            'Email server timed out. Please try again in a moment.'
          );
        }
        throw error;
      }
      throw new Error('Failed to send verification email');
    }
  },
};

export const adminNotificationsApi = {
  sendBulk: async (
    payload: SendBulkNotificationPayload
  ): Promise<BulkSendResult> => {
    const body: Record<string, unknown> = {
      userIds: payload.userIds,
      title: payload.title,
      body: payload.body,
    };
    if (payload.type) {
      body.type = payload.type;
    }
    const response = await apiClient.post<MoiApiResponse<BulkSendResult>>(
      '/notification/admin/send-bulk',
      body,
      {
        timeout: BULK_SEND_TIMEOUT_MS,
        skipErrorHandler: true,
      }
    );
    return assertSuccess(response.data);
  },
};
