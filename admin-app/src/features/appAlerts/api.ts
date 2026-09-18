import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
  totalCount?: number;
}

export interface AppAlertItem {
  id: string;
  title: string;
  content: string;
  imageUrl?: string | null;
  videoUrl?: string | null;
  ctaLabel?: string | null;
  ctaUrl?: string | null;
  isActive: boolean;
  startsAt?: string | null;
  endsAt?: string | null;
  createdByAdminId?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface CreateAppAlertPayload {
  title: string;
  content: string;
  imageUrl?: string;
  videoUrl?: string;
  ctaLabel?: string;
  ctaUrl?: string;
  isActive?: boolean;
}

export interface AppAlertListResult {
  data: AppAlertItem[];
  count: number;
  totalCount: number;
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
  if (String(data.responseType).toUpperCase() !== 'S') {
    throw new Error(extractErrorMessage(data));
  }
  return data.responseValue;
}

function rethrowApiError(error: unknown): never {
  if (error && typeof error === 'object' && 'response' in error) {
    const data = (error as { response?: { data?: MoiApiResponse<unknown> } }).response
      ?.data;
    if (data) throw new Error(extractErrorMessage(data));
  }
  if (error instanceof Error) throw error;
  throw new Error('Request failed');
}

export const appAlertsApi = {
  list: async ({
    page = 1,
    limit = 20,
  }: { page?: number; limit?: number } = {}): Promise<AppAlertListResult> => {
    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.max(1, Number(limit) || 20);
    const offset = (safePage - 1) * safeLimit;

    try {
      const response = await apiClient.get<MoiApiResponse<AppAlertItem[]>>(
        '/app-alert/admin/list',
        { params: { limit: safeLimit, offset }, skipErrorHandler: true }
      );
      const data = response.data;
      if (String(data.responseType).toUpperCase() !== 'S') {
        throw new Error(extractErrorMessage(data));
      }
      const list = Array.isArray(data.responseValue) ? data.responseValue : [];
      return {
        data: list,
        count: Number(data.count ?? list.length),
        totalCount: Number(data.totalCount ?? list.length),
      };
    } catch (error) {
      rethrowApiError(error);
    }
  },

  create: async (payload: CreateAppAlertPayload): Promise<AppAlertItem> => {
    try {
      const response = await apiClient.post<MoiApiResponse<AppAlertItem>>(
        '/app-alert/admin/create',
        payload,
        { skipErrorHandler: true }
      );
      return assertSuccess(response.data);
    } catch (error) {
      rethrowApiError(error);
    }
  },

  update: async (
    alertId: string,
    payload: Partial<CreateAppAlertPayload>
  ): Promise<AppAlertItem> => {
    try {
      const response = await apiClient.post<MoiApiResponse<AppAlertItem>>(
        '/app-alert/admin/update',
        { alertId, ...payload },
        { skipErrorHandler: true }
      );
      return assertSuccess(response.data);
    } catch (error) {
      rethrowApiError(error);
    }
  },

  remove: async (alertId: string): Promise<void> => {
    try {
      const response = await apiClient.post<MoiApiResponse<{ message?: string }>>(
        '/app-alert/admin/delete',
        { alertId },
        { skipErrorHandler: true }
      );
      assertSuccess(response.data);
    } catch (error) {
      rethrowApiError(error);
    }
  },
};
