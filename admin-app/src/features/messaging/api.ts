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

export const emailApi = {
  sendBulk: async (payload: SendBulkEmailPayload): Promise<BulkSendResult> => {
    const response = await apiClient.post<MoiApiResponse<BulkSendResult>>(
      '/email/admin/send-bulk',
      payload
    );
    return assertSuccess(response.data);
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
      body
    );
    return assertSuccess(response.data);
  },
};
