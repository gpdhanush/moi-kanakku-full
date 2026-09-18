import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
}

export type UpcomingFunctionStatus = 'ACTIVE' | 'CANCELLED' | 'COMPLETED';

export interface UpcomingFunctionItem {
  id: string;
  userId: string;
  userName?: string | null;
  userEmail?: string | null;
  userMobile?: string | null;
  title: string;
  description?: string | null;
  functionDate: string | null;
  location?: string | null;
  invitationUrl?: string | null;
  status?: UpcomingFunctionStatus | string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface UpcomingFunctionListResult {
  count: number;
  data: UpcomingFunctionItem[];
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

export const upcomingFunctionsApi = {
  list: async (userId?: string): Promise<UpcomingFunctionListResult> => {
    const response = await apiClient.post<MoiApiResponse<UpcomingFunctionItem[]>>(
      '/upcoming-functions/admin/list',
      userId ? { userId } : {}
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
};
