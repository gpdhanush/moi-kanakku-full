import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | string;
  responseValue: T;
  responseMessage?: string;
}

export interface DashboardStat {
  title: string;
  count: number | string;
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

export const dashboardApi = {
  getStats: async (): Promise<DashboardStat[]> => {
    const response = await apiClient.get<MoiApiResponse<DashboardStat[]>>('/dashboard');
    return assertSuccess(response.data);
  },
};
