import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
}

export interface TransactionPerson {
  firstName?: string | null;
  lastName?: string | null;
  mobile?: string | null;
  city?: string | null;
  occupation?: string | null;
}

export interface TransactionFunction {
  name?: string | null;
  date?: string | null;
  location?: string | null;
}

export interface TransactionItem {
  id: string;
  userId: string;
  userName: string;
  userEmail: string;
  userMobile: string;
  personId: string;
  transactionFunctionId: string;
  transactionFunctionName: string;
  transactionDate: string;
  type: string;
  amount: string | number;
  itemName: string | null;
  notes: string | null;
  isCustom: boolean;
  customFunction: string | null;
  person?: TransactionPerson | null;
  function?: TransactionFunction | null;
  createdAt: string;
  updatedAt: string;
}

export interface TransactionListResult {
  count: number;
  data: TransactionItem[];
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

export const transactionsApi = {
  list: async (userId?: string): Promise<TransactionListResult> => {
    const response = await apiClient.post<MoiApiResponse<TransactionItem[]>>(
      '/transactions/admin/list',
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
