import { apiClient } from '@/lib/axios';

export type ExportPaymentStatus = 'pending' | 'approved' | 'rejected';
export type ExportPaymentStatusFilter = ExportPaymentStatus | 'all';

export type ExportPlanId = 'single' | 'pack5' | 'lifetime';

/** Fixed export plan offered in the app. `exports: null` = unlimited (lifetime). */
export interface ExportPlan {
  id: ExportPlanId;
  exports: number | null;
  lifetime: boolean;
  amount: number;
  upiUri: string | null;
}

/** '1 export', '5 exports' or 'Unlimited (lifetime)'. */
export function planLabel(planId: string | null, exports: number | null): string {
  if (planId === 'lifetime' || (planId && exports == null)) return 'Unlimited (lifetime)';
  if (exports == null) return '—';
  return `${exports} export${exports === 1 ? '' : 's'}`;
}

export interface ExportPayment {
  id: string;
  userId: string;
  userName: string | null;
  userEmail: string | null;
  userMobile: string | null;
  amount: number;
  /** Plan the user paid for; null on payments made before plans existed. */
  plan: ExportPlanId | null;
  upiTxnId: string;
  status: ExportPaymentStatus;
  /** PDF exports this payment buys / has used (set on approval). */
  exportsAllowed: number | null;
  exportsUsed: number | null;
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

export interface ExportPaymentSettings {
  upiId: string;
  payeeName: string;
  plans: ExportPlan[];
  qrImageUrl: string | null;
  upiUri: string | null;
  configured: boolean;
  updatedAt: string | null;
  updatedByName: string | null;
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

function unwrap<T>(body: ApiResponse<T>, fallback: string): T {
  if (body.responseType !== 'S') throw new Error(messageFrom(body.responseValue, fallback));
  return body.responseValue;
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

  getSettings: async (): Promise<ExportPaymentSettings> => {
    try {
      const response = await apiClient.get<ApiResponse<ExportPaymentSettings>>(
        '/export-payments/admin/settings',
        { skipErrorHandler: true }
      );
      return unwrap(response.data, 'Failed to load payment settings.');
    } catch (error) {
      rethrow(error, 'Failed to load payment settings.');
    }
  },

  saveSettings: async (payload: {
    upiId: string;
    payeeName: string;
  }): Promise<ExportPaymentSettings> => {
    try {
      const response = await apiClient.put<ApiResponse<ExportPaymentSettings>>(
        '/export-payments/admin/settings',
        payload,
        { skipErrorHandler: true }
      );
      return unwrap(response.data, 'Failed to save payment settings.');
    } catch (error) {
      rethrow(error, 'Failed to save payment settings.');
    }
  },

  uploadQr: async (file: File): Promise<ExportPaymentSettings> => {
    try {
      const form = new FormData();
      form.append('file', file);
      const response = await apiClient.post<ApiResponse<ExportPaymentSettings>>(
        '/export-payments/admin/settings/qr',
        form,
        { skipErrorHandler: true }
      );
      return unwrap(response.data, 'Failed to upload QR image.');
    } catch (error) {
      rethrow(error, 'Failed to upload QR image.');
    }
  },

  removeQr: async (): Promise<ExportPaymentSettings> => {
    try {
      const response = await apiClient.delete<ApiResponse<ExportPaymentSettings>>(
        '/export-payments/admin/settings/qr',
        { skipErrorHandler: true }
      );
      return unwrap(response.data, 'Failed to remove QR image.');
    } catch (error) {
      rethrow(error, 'Failed to remove QR image.');
    }
  },
};
