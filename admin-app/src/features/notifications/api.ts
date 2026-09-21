import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
  totalCount?: number;
  unreadCount?: number;
}

export interface NotificationItem {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: string;
  isRead: boolean;
  readAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminNotificationItem extends NotificationItem {
  userName?: string | null;
  userEmail?: string | null;
  userMobile?: string | null;
}

export interface NotificationListParams {
  page?: number;
  limit?: number;
}

export interface NotificationListResult {
  /** Items returned on the current page. */
  count: number;
  /** Grand total of notifications for this user. */
  totalCount: number;
  unreadCount: number;
  data: NotificationItem[];
  page: number;
  limit: number;
  pages: number;
}

export interface AdminNotificationListResult {
  count: number;
  totalCount: number;
  unreadCount: number;
  data: AdminNotificationItem[];
  page: number;
  limit: number;
  pages: number;
}

export interface NotificationDeleteResult {
  message?: string;
  deletedCount?: number;
  notificationId?: string;
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

function rethrowApiError(error: unknown): never {
  if (error && typeof error === 'object' && 'response' in error) {
    const data = (error as { response?: { data?: MoiApiResponse<unknown> } }).response
      ?.data;
    if (data) {
      throw new Error(extractErrorMessage(data));
    }
  }
  if (error instanceof Error) throw error;
  throw new Error('Request failed');
}

function parseListResult<T>(
  data: MoiApiResponse<T[]>,
  page: number,
  limit: number
): {
  count: number;
  totalCount: number;
  unreadCount: number;
  data: T[];
  page: number;
  limit: number;
  pages: number;
} {
  if (String(data.responseType).toUpperCase() !== 'S') {
    throw new Error(extractErrorMessage(data));
  }

  const list = Array.isArray(data.responseValue) ? data.responseValue : [];
  const pageCount = Number(data.count ?? list.length);
  const totalCount = Number(data.totalCount ?? pageCount);
  const pages = Math.max(1, Math.ceil(totalCount / limit) || 1);

  return {
    count: pageCount,
    totalCount,
    unreadCount: Number(data.unreadCount ?? 0),
    data: list,
    page,
    limit,
    pages,
  };
}

export const notificationsApi = {
  listByUser: async (
    userId: string,
    { page = 1, limit = 10 }: NotificationListParams = {}
  ): Promise<NotificationListResult> => {
    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.max(1, Number(limit) || 10);
    const offset = (safePage - 1) * safeLimit;

    const response = await apiClient.get<MoiApiResponse<NotificationItem[]>>(
      `/notification/admin/user-notifications/${userId}`,
      {
        params: {
          limit: safeLimit,
          offset,
        },
        skipErrorHandler: true,
      }
    );

    return parseListResult(response.data, safePage, safeLimit);
  },

  listAll: async ({
    page = 1,
    limit = 10,
  }: NotificationListParams = {}): Promise<AdminNotificationListResult> => {
    const safePage = Math.max(1, Number(page) || 1);
    const safeLimit = Math.max(1, Number(limit) || 10);
    const offset = (safePage - 1) * safeLimit;

    const response = await apiClient.get<MoiApiResponse<AdminNotificationItem[]>>(
      '/notification/admin/all',
      {
        params: {
          limit: safeLimit,
          offset,
        },
      }
    );

    return parseListResult(response.data, safePage, safeLimit);
  },

  deleteOne: async (notificationId: string): Promise<NotificationDeleteResult> => {
    try {
      const response = await apiClient.post<MoiApiResponse<NotificationDeleteResult>>(
        '/notification/admin/delete',
        { notificationId: String(notificationId) },
        { skipErrorHandler: true }
      );
      return (
        assertSuccess(response.data) ?? {
          message: 'Notification deleted successfully',
          notificationId: String(notificationId),
        }
      );
    } catch (error) {
      rethrowApiError(error);
    }
  },

  deleteBulk: async (
    notificationIds: string[]
  ): Promise<NotificationDeleteResult> => {
    try {
      const response = await apiClient.post<MoiApiResponse<NotificationDeleteResult>>(
        '/notification/admin/delete-bulk',
        { notificationIds: notificationIds.map(String) },
        { skipErrorHandler: true }
      );
      const result =
        assertSuccess(response.data) ?? {
          message: 'Selected notifications deleted successfully',
          deletedCount: notificationIds.length,
        };
      if (typeof result.deletedCount === 'number' && result.deletedCount < 1) {
        throw new Error('Unable to delete selected notifications.');
      }
      return result;
    } catch (error) {
      rethrowApiError(error);
    }
  },

  deleteByScope: async (
    scope: 'read' | 'unread' | 'all'
  ): Promise<NotificationDeleteResult> => {
    try {
      const response = await apiClient.post<MoiApiResponse<NotificationDeleteResult>>(
        '/notification/admin/delete-by-scope',
        { scope },
        { skipErrorHandler: true }
      );
      return (
        assertSuccess(response.data) ?? {
          message: 'Notifications deleted successfully',
          deletedCount: 0,
        }
      );
    } catch (error) {
      rethrowApiError(error);
    }
  },
};

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (String(data.responseType).toUpperCase() !== 'S') {
    throw new Error(extractErrorMessage(data));
  }
  return data.responseValue;
}
