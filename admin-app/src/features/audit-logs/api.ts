import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
}

export interface AuditLogItem {
  id: number | string;
  user_id: string;
  name: string;
  email?: string | null;
  mobile?: string | null;
  action: string;
  entity_type?: string | null;
  entity_id?: string | null;
  summary: string;
  metadata?: Record<string, unknown> | null;
  ip_address?: string | null;
  user_agent?: string | null;
  device_id?: string | null;
  created_at: string;
}

export interface AuditLogPagination {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

export interface AuditLogListResult {
  message: string;
  data: AuditLogItem[];
  pagination: AuditLogPagination;
}

export interface AuditLogListParams {
  page?: number;
  limit?: number;
  userId?: string;
  action?: string;
  q?: string;
}

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (data.responseType !== 'S') {
    const message =
      data.responseMessage ||
      (typeof data.responseValue === 'string'
        ? data.responseValue
        : (data.responseValue as { message?: string })?.message) ||
      'Request failed';
    throw new Error(String(message));
  }
  return data.responseValue;
}

export const AUDIT_ACTIONS = [
  'ALL',
  'LOGIN',
  'LOGOUT',
  'SIGNUP',
  'PROFILE_UPDATE',
  'PASSWORD_UPDATE',
  'PASSWORD_RESET',
  'ACCOUNT_DELETE',
  'ACCOUNT_RESTORE',
  'DEVICE_REGISTER',
  'PROFILE_PHOTO_UPDATE',
  'PERSON_CREATE',
  'PERSON_UPDATE',
  'PERSON_DELETE',
  'FUNCTION_CREATE',
  'FUNCTION_UPDATE',
  'FUNCTION_DELETE',
  'TRANSACTION_CREATE',
  'TRANSACTION_UPDATE',
  'TRANSACTION_DELETE',
  'UPCOMING_CREATE',
  'UPCOMING_UPDATE',
  'UPCOMING_STATUS',
  'UPCOMING_DELETE',
  'FEEDBACK_CREATE',
] as const;

export type AuditActionFilter = (typeof AUDIT_ACTIONS)[number];

export const auditLogsApi = {
  list: async ({
    page = 1,
    limit = 10,
    userId,
    action,
    q,
  }: AuditLogListParams = {}): Promise<AuditLogListResult> => {
    const params: Record<string, string | number> = { page, limit };
    if (userId) params.userId = userId;
    if (action && action !== 'ALL') params.action = action;
    if (q?.trim()) params.q = q.trim();

    const response = await apiClient.get<MoiApiResponse<AuditLogListResult>>(
      '/admin/audit-logs',
      { params }
    );
    return assertSuccess(response.data);
  },

  deleteBulk: async (
    ids: Array<number | string>
  ): Promise<{ message?: string; deletedCount?: number }> => {
    const response = await apiClient.post<
      MoiApiResponse<{ message?: string; deletedCount?: number }>
    >(
      '/admin/audit-logs/delete-bulk',
      { ids },
      { skipErrorHandler: true }
    );
    return assertSuccess(response.data);
  },
};
