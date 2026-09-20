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

export interface DashboardAnalytics {
  month: string;
  previousMonth: string;
  summary: {
    monthSignups: number;
    previousMonthSignups: number;
    changePercent: number;
    todaySignups: number;
  };
  dailySignups: { date: string; count: number }[];
  recentLogins: {
    id: string | null;
    name: string;
    email: string | null;
    city: string | null;
    lastLogin: string | null;
  }[];
  recentSignups: {
    id: string | null;
    name: string;
    email: string | null;
    city: string | null;
    createdAt: string | null;
  }[];
  cityBreakdown: { city: string; count: number }[];
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
  getAnalytics: async (month: string): Promise<DashboardAnalytics> => {
    const response = await apiClient.get<MoiApiResponse<DashboardAnalytics>>('/dashboard/analytics', {
      params: { month },
    });
    return assertSuccess(response.data);
  },
};
