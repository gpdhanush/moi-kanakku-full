import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
}

export interface PersonItem {
  id: string;
  firstName: string | null;
  secondName: string | null;
  business: string | null;
  city: string | null;
  mobile: string | null;
  userId: string;
  userName?: string | null;
  userEmail?: string | null;
  userMobile?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface PersonListResult {
  count: number;
  data: PersonItem[];
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

export const personsApi = {
  listByUser: async (userId: string): Promise<PersonListResult> => {
    const response = await apiClient.get<MoiApiResponse<PersonItem[]>>(
      `/persons/admin/${userId}`
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
