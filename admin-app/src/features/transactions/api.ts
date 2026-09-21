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

export interface TransactionDeleteResult {
  message?: string;
  transactionId?: string;
  deletedCount?: number;
}

async function fetchPage(
  page: number,
  limit: number,
  userId?: string
): Promise<MoiApiResponse<TransactionItem[]>> {
  const response = await apiClient.post<MoiApiResponse<TransactionItem[]>>(
    '/transactions/admin/list',
    {
      ...(userId ? { userId } : {}),
      page,
      limit,
      },
      { skipErrorHandler: true }
  );
  return response.data;
}

export const transactionsApi = {
  list: async (
    userId?: string,
    opts?: { page?: number; limit?: number }
  ): Promise<TransactionListResult> => {
    // When page is provided, return a single server page.
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

    // Legacy callers: page-loop so UI can keep client-side filter/sort.
    const all: TransactionItem[] = [];
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

  delete: async (transactionId: string): Promise<TransactionDeleteResult> => {
    const response = await apiClient.post<MoiApiResponse<TransactionDeleteResult>>(
      '/transactions/admin/delete',
      { transactionId: String(transactionId) },
      { skipErrorHandler: true }
    );
    const data = response.data;
    if (data.responseType !== 'S') {
      throw new Error(extractErrorMessage(data));
    }
    return data.responseValue ?? { message: 'Transaction deleted successfully.' };
  },

  deleteBulk: async (
    transactionIds: string[]
  ): Promise<TransactionDeleteResult> => {
    const response = await apiClient.post<MoiApiResponse<TransactionDeleteResult>>(
      '/transactions/admin/delete-bulk',
      { transactionIds },
      { skipErrorHandler: true }
    );
    const data = response.data;
    if (data.responseType !== 'S') {
      throw new Error(extractErrorMessage(data));
    }
    return (
      data.responseValue ?? {
        message: 'Selected transactions deleted successfully',
        deletedCount: transactionIds.length,
      }
    );
  },
};
