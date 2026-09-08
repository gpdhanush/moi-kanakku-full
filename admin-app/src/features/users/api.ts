import { apiClient } from '@/lib/axios';

export interface MoiApiResponse<T> {
  responseType: 'S' | 'E' | 'F' | string;
  responseValue: T;
  responseMessage?: string;
  count?: number;
}

export interface UserListItem {
  id: string;
  mobile: string | null;
  name: string;
  last_login: string | null;
  city: string | null;
  profile_image_url: string | null;
  device_name: string | null;
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
  fcm_token?: string | null;
  device_name?: string | null;
  device_id?: string | null;
  is_active?: number | boolean | null;
  last_used_at?: string | null;
  brand?: string | null;
  model?: string | null;
  manufacturer?: string | null;
  androidVersion?: string | null;
  ram_size?: string | null;
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
  list: async (): Promise<UserListItem[]> => {
    const response = await apiClient.get<MoiApiResponse<UserListItem[]>>(
      '/users/admin/all-user-lists'
    );
    return assertSuccess(response.data) ?? [];
  },

  getById: async (userId: string): Promise<UserDetail> => {
    const response = await apiClient.get<MoiApiResponse<UserDetail>>(
      `/users/admin/all-user-lists/${userId}`
    );
    return assertSuccess(response.data);
  },
};
