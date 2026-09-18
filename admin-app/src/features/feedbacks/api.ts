import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
}

export interface FeedbackItem {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  type: string;
  message: string;
  adminResponse: string | null;
  status: string;
  respondedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface FeedbackListResult {
  count: number;
  data: FeedbackItem[];
}

export type FeedbackStatus = 'IN_PROGRESS' | 'RESOLVED';

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

function rethrowApiError(error: unknown): never {
  if (error && typeof error === 'object' && 'response' in error) {
    const data = (error as { response?: { data?: MoiApiResponse<unknown> } }).response
      ?.data;
    if (data) {
      throw new Error(extractErrorMessage(data));
    }
  }
  if (error instanceof Error) throw error;
  throw new Error('Request failed');
}

export const feedbacksApi = {
  list: async (): Promise<FeedbackListResult> => {
    const response = await apiClient.get<MoiApiResponse<FeedbackItem[]>>(
      '/feedbacks/admin/all-feedback-lists'
    );
    const data = response.data;
    if (data.responseType !== 'S') {
      throw new Error(extractErrorMessage(data));
    }
    return {
      count: data.count ?? data.responseValue?.length ?? 0,
      data: data.responseValue ?? [],
    };
  },

  reply: async (payload: {
    feedbackId: string;
    adminResponse: string;
    status: FeedbackStatus;
  }): Promise<{ message?: string }> => {
    const response = await apiClient.post<MoiApiResponse<{ message?: string }>>(
      '/feedbacks/admin/reply-feedback',
      payload
    );
    return assertSuccess(response.data) ?? { message: 'Reply sent successfully' };
  },

  delete: async (feedbackId: string): Promise<{ message?: string; feedbackId?: string }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{ message?: string; feedbackId?: string }>
      >('/feedbacks/admin/delete-feedback', { feedbackId }, { skipErrorHandler: true });
      return assertSuccess(response.data);
    } catch (error) {
      rethrowApiError(error);
    }
  },

  deleteBulk: async (
    feedbackIds: string[]
  ): Promise<{ message?: string; deletedCount?: number }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{ message?: string; deletedCount?: number }>
      >(
        '/feedbacks/admin/delete-bulk',
        { feedbackIds },
        { skipErrorHandler: true }
      );
      return assertSuccess(response.data);
    } catch (error) {
      rethrowApiError(error);
    }
  },

  deleteByScope: async (
    scope: 'pending' | 'resolved' | 'all'
  ): Promise<{ message?: string; deletedCount?: number; scope?: string }> => {
    try {
      const response = await apiClient.post<
        MoiApiResponse<{ message?: string; deletedCount?: number; scope?: string }>
      >(
        '/feedbacks/admin/delete-by-scope',
        { scope },
        { skipErrorHandler: true }
      );
      return assertSuccess(response.data);
    } catch (error) {
      rethrowApiError(error);
    }
  },
};
