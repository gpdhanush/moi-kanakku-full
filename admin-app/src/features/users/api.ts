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

export type AppInstallStatus =
  | 'ACTIVE'
  | 'INACTIVE'
  | 'LIKELY_UNINSTALLED'
  | 'UNKNOWN';

export interface UserListItem {
  id: string;
  mobile: string | null;
  name: string;
  last_login: string | null;
  city: string | null;
  profile_image_url: string | null;
  device_name: string | null;
  status?: string | null;
  app_status?: AppInstallStatus | string | null;
  last_seen_at?: string | null;
  device_count?: number | null;
  platforms?: string[] | null;
  app_version?: string | null;
  signup_type?: string | null;
  google_linked?: boolean | number | null;
  password_set?: boolean | number | null;
  is_verified?: boolean | number | null;
}

export interface UserProfile {
  gender?: string | null;
  date_of_birth?: string | null;
  address_line1?: string | null;
  address_line2?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string | null;
  postal_code?: string | null;
  profile_image_url?: string | null;
}

export interface UserDevice {
  id?: string;
  device_name?: string | null;
  device_id?: string | null;
  is_active?: number | boolean | null;
  last_used_at?: string | null;
  brand?: string | null;
  model?: string | null;
  manufacturer?: string | null;
  androidVersion?: string | null;
  android_version?: string | null;
  ram_size?: string | null;
  platform?: string | null;
  app_version?: string | null;
  token_status?: string | null;
  uninstalled_at?: string | null;
  created_at?: string | null;
  install_status?: AppInstallStatus | string | null;
}

export interface UserDetail {
  id: string;
  name: string;
  email: string | null;
  mobile: string | null;
  last_login: string | null;
  profile?: UserProfile | null;
  device?: UserDevice | null;
  referrer_id?: string | null;
  referred_count?: number | null;
  create_date?: string | null;
  update_date?: string | null;
  status?: string | null;
  referral_code?: string | null;
  is_verified?: number | boolean | null;
  email_verified_at?: string | null;
  devices?: UserDevice[] | null;
  app_status?: AppInstallStatus | string | null;
  last_seen_at?: string | null;
  device_count?: number | null;
  platforms?: string[] | null;
  app_version?: string | null;
  signup_type?: string | null;
  google_linked?: boolean | number | null;
  password_set?: boolean | number | null;
  is_verified?: boolean | number | null;
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === 'object' && 'message' in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === 'string') return value;
  return data.responseMessage || 'Request failed';
}

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (data.responseType !== 'S') {
    throw new Error(extractErrorMessage(data));
  }
  return data.responseValue;
}

export const usersApi = {
  list: async (opts?: { page?: number; limit?: number }): Promise<UserListItem[]> => {
    if (opts?.page != null) {
      const response = await apiClient.get<MoiApiResponse<UserListItem[]>>(
        '/users/admin/all-user-lists',
        { params: { page: opts.page, limit: opts.limit ?? 30 } }
      );
      return assertSuccess(response.data) ?? [];
    }

    const all: UserListItem[] = [];
    let page = 1;
    let hasMore = true;
    while (hasMore) {
      const response = await apiClient.get<MoiApiResponse<UserListItem[]>>(
        '/users/admin/all-user-lists',
        { params: { page, limit: 100 } }
      );
      const data = response.data;
      if (data.responseType !== 'S') {
        throw new Error(extractErrorMessage(data));
      }
      const chunk = data.responseValue ?? [];
      all.push(...chunk);
      hasMore = data.hasMore === true && chunk.length > 0;
      page += 1;
      if (page > 500) break;
    }
    return all;
  },

  getById: async (userId: string): Promise<UserDetail> => {
    const response = await apiClient.get<MoiApiResponse<UserDetail>>(
      `/users/admin/all-user-lists/${userId}`
    );
    return assertSuccess(response.data);
  },

  updateStatus: async (
    userId: string,
    status: "ACTIVE" | "INACTIVE" | "BLOCKED"
  ): Promise<{ message?: string; userId?: string; status?: string }> => {
    const response = await apiClient.post<
      MoiApiResponse<{ message?: string; userId?: string; status?: string }>
    >("/users/admin/update-status", {
      userId: String(userId),
      status,
    });
    return assertSuccess(response.data);
  },

  restore: async (
    userId: string
  ): Promise<{ message?: string; userId?: string; status?: string }> => {
    const response = await apiClient.post<
      MoiApiResponse<{ message?: string; userId?: string; status?: string }>
    >("/users/admin/restore", { userId: String(userId) });
    return assertSuccess(response.data);
  },

  deleteUser: async (
    userId: string,
    mode: "soft" | "permanent"
  ): Promise<{ message?: string; userId?: string; mode?: string }> => {
    const response = await apiClient.post<
      MoiApiResponse<{ message?: string; userId?: string; mode?: string }>
    >("/users/admin/delete", {
      userId: String(userId),
      mode,
    });
    return assertSuccess(response.data);
  },
};
