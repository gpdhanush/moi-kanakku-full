import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | string;
  responseValue: T;
  responseMessage?: string;
}

export interface OtpRecord {
  id: number;
  user_id: string;
  name: string;
  email: string;
  mobile: string;
  code: string;
  type: string;
  expires_at: string;
  is_used: boolean;
  created_at: string;
}

export interface OtpPagination {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

export interface OtpListResult {
  message: string;
  data: OtpRecord[];
  pagination: OtpPagination;
}

export interface OtpCleanupResult {
  message: string;
  deleted_count: number;
}

export interface OtpListParams {
  page?: number;
  limit?: number;
}

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (data.responseType !== 'S') {
    const message =
      data.responseMessage ||
      (typeof data.responseValue === 'string' ? data.responseValue : 'Request failed');
    throw new Error(String(message));
  }
  return data.responseValue;
}

export const otpsApi = {
  list: async ({ page = 1, limit = 10 }: OtpListParams = {}): Promise<OtpListResult> => {
    const response = await apiClient.get<MoiApiResponse<OtpListResult>>('/admin/otps', {
      params: { page, limit },
    });
    return assertSuccess(response.data);
  },

  cleanupExpired: async (): Promise<OtpCleanupResult> => {
    const response = await apiClient.delete<MoiApiResponse<OtpCleanupResult>>('/admin/otps/cleanup');
    return assertSuccess(response.data);
  },
};
