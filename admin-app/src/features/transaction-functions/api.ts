import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
  page?: number;
  limit?: number;
  hasMore?: boolean;
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
  page?: number;
  limit?: number;
  hasMore?: boolean;
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

async function fetchPage(
  page: number,
  limit: number,
  userId?: string
): Promise<MoiApiResponse<TransactionFunctionItem[]>> {
  const response = await apiClient.post<MoiApiResponse<TransactionFunctionItem[]>>(
    '/transaction-functions/admin/list',
    {
      ...(userId ? { userId } : {}),
      page,
      limit,
      },
      { skipErrorHandler: true }
  );
  return response.data;
}

export const transactionFunctionsApi = {
  list: async (
    userId?: string,
    opts?: { page?: number; limit?: number }
  ): Promise<TransactionFunctionListResult> => {
    if (opts?.page != null) {
      const limit = opts.limit ?? 30;
      const data = await fetchPage(opts.page, limit, userId);
      if (data.responseType !== 'S') {
        throw new Error(extractErrorMessage(data));
      }
      return {
        count: data.count ?? data.responseValue?.length ?? 0,
        data: data.responseValue ?? [],
        page: data.page,
        limit: data.limit,
        hasMore: data.hasMore,
      };
    }

    const all: TransactionFunctionItem[] = [];
    let page = 1;
    let total = 0;
    let hasMore = true;
    while (hasMore) {
      const data = await fetchPage(page, 100, userId);
      if (data.responseType !== 'S') {
        throw new Error(extractErrorMessage(data));
      }
      const chunk = data.responseValue ?? [];
      all.push(...chunk);
      total = data.count ?? all.length;
      hasMore = data.hasMore === true && chunk.length > 0;
      page += 1;
      if (page > 500) break;
    }
    return { count: total, data: all };
  },
};
