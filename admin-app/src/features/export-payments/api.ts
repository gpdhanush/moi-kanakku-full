import { apiClient } from '@/lib/axios';

export type ExportPaymentStatus = 'pending' | 'approved' | 'rejected';
export type ExportPaymentStatusFilter = ExportPaymentStatus | 'all';

export interface ExportPayment {
  id: string;
  userId: string;
  userName: string | null;
  userEmail: string | null;
  userMobile: string | null;
  amount: number;
  upiTxnId: string;
  status: ExportPaymentStatus;
  adminRemarks: string;
  reviewedBy: string | null;
  reviewedByName: string | null;
  reviewedAt: string | null;
  createdAt: string | null;
  updatedAt: string | null;
}

export interface ExportPaymentStats {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
}

export interface ExportPaymentListResult {
  data: ExportPayment[];
  pagination: { page: number; limit: number; total: number; totalPages: number };
  stats: ExportPaymentStats;
}

interface ApiResponse<T> {
  responseType: string;
  responseValue: T;
  pagination?: ExportPaymentListResult['pagination'];
  stats?: ExportPaymentStats;
}

function messageFrom(value: unknown, fallback: string): string {
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: unknown }).message);
  }
  return fallback;
}

function rethrow(error: unknown, fallback: string): never {
  const data = (error as { response?: { data?: ApiResponse<unknown> } })?.response?.data;
  if (data) throw new Error(messageFrom(data.responseValue, fallback));
  if (error instanceof Error) throw error;
  throw new Error(fallback);
}

export const exportPaymentsApi = {
  list: async (params: {
    page: number;
    limit: number;
    status: ExportPaymentStatusFilter;
    search?: string;
  }): Promise<ExportPaymentListResult> => {
    try {
      const response = await apiClient.get<ApiResponse<ExportPayment[]>>(
        '/export-payments/admin/list',
        {
          params: {
            page: params.page,
            limit: params.limit,
            status: params.status === 'all' ? undefined : params.status,
            search: params.search || undefined,
          },
          skipErrorHandler: true,
        }
      );
      const body = response.data;
      if (body.responseType !== 'S') {
        throw new Error(messageFrom(body.responseValue, 'Failed to load payments.'));
      }
      return {
        data: body.responseValue ?? [],
        pagination: body.pagination ?? {
          page: params.page,
          limit: params.limit,
          total: body.responseValue?.length ?? 0,
          totalPages: 1,
        },
        stats: body.stats ?? { total: 0, pending: 0, approved: 0, rejected: 0 },
      };
    } catch (error) {
      rethrow(error, 'Failed to load payments.');
    }
  },

  review: async (payload: {
    paymentId: string;
    action: 'approve' | 'reject';
    remarks?: string;
  }): Promise<ExportPayment> => {
    try {
      const response = await apiClient.post<ApiResponse<ExportPayment>>(
        '/export-payments/admin/review',
        payload,
        { skipErrorHandler: true }
      );
      if (response.data.responseType !== 'S') {
        throw new Error(messageFrom(response.data.responseValue, 'Update failed.'));
      }
      return response.data.responseValue;
    } catch (error) {
      rethrow(error, 'Update failed.');
    }
  },
};
