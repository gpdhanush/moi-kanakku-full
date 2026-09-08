import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
}

export interface TransactionFunctionItem {
  id: string;
  userId: string;
  functionName: string;
  functionDate: string | null;
  location: string | null;
  notes: string | null;
  imageUrl: string | null;
  userName?: string | null;
  userEmail?: string | null;
  userMobile?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
}

export interface TransactionFunctionListResult {
  count: number;
  data: TransactionFunctionItem[];
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

export const transactionFunctionsApi = {
  list: async (userId?: string): Promise<TransactionFunctionListResult> => {
    const response = await apiClient.post<MoiApiResponse<TransactionFunctionItem[]>>(
      '/transaction-functions/admin/list',
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
