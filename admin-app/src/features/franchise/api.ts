import { apiClient } from '@/lib/axios';
import type { MoiApiResponse } from '@/features/auth/api';

export interface FranchiseBranch {
  id: number;
  name: string;
  code: string;
  mobile?: string;
  email?: string;
  address?: string;
  city?: string;
  state?: string;
  pincode?: string;
  status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED';
  created_at?: string;
  updated_at?: string;
  admin_count?: number;
  customer_count?: number;
  staff_count?: number;
  function_count?: number;
}

export interface FranchiseAdminUser {
  id: number;
  admin_id: number;
  franchise_id: number;
  full_name?: string;
  email?: string;
  mobile?: string;
  assigned_at?: string;
}

export interface FranchiseCustomer {
  id: number;
  user_id: number;
  franchise_id: number;
  customer_code: string;
  status: 'ACTIVE' | 'INACTIVE';
  created_at: string;
  full_name?: string;
  email?: string;
  mobile?: string;
  city?: string;
}

export interface FranchiseStaff {
  id: number;
  user_id: number;
  franchise_id: number;
  status: 'ACTIVE' | 'INACTIVE';
  created_at: string;
  full_name?: string;
  email?: string;
  mobile?: string;
  permissions?: FranchiseStaffPermission[];
}

export interface FranchiseStaffPermission {
  function_id: number;
  function_name?: string;
  can_view: boolean;
  can_add_customer: boolean;
  can_add_transaction: boolean;
  can_edit_transaction: boolean;
  can_delete_transaction: boolean;
  can_view_report: boolean;
}

export interface FranchiseFunction {
  id: number;
  franchise_id: number;
  name: string;
  function_date: string;
  location?: string;
  event_type?: string;
  status: 'ACTIVE' | 'COMPLETED' | 'CANCELLED';
  created_at: string;
  total_persons?: number;
  total_amount?: number;
}

export interface FranchiseAuditLog {
  id: number;
  franchise_id: number;
  actor_type: string;
  actor_id: number;
  action: string;
  details?: any;
  created_at: string;
}

export interface FranchiseDashboardStats {
  totalCustomers: number;
  totalStaff: number;
  totalFunctions: number;
  totalTransactions: number;
  totalAmountCollected: number;
  recentActivities?: FranchiseAuditLog[];
}

export const franchiseApi = {
  // ==========================================
  // SUPER ADMIN APIS
  // ==========================================
  listFranchises: async (params?: { limit?: number; offset?: number; search?: string }) => {
    const response = await apiClient.get<MoiApiResponse<{ franchises: FranchiseBranch[]; total: number }>>(
      '/franchises/super-admin',
      { params }
    );
    return response.data.responseValue;
  },

  createFranchise: async (payload: {
    name: string;
    code: string;
    mobile?: string;
    email?: string;
    address?: string;
    city?: string;
    state?: string;
    pincode?: string;
  }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string; franchise: FranchiseBranch }>>(
      '/franchises/super-admin',
      payload
    );
    return response.data.responseValue;
  },

  getFranchise: async (id: number) => {
    const response = await apiClient.get<MoiApiResponse<{
      franchise: FranchiseBranch;
      admins: FranchiseAdminUser[];
      summary: any;
    }>>(`/franchises/super-admin/${id}`);
    return response.data.responseValue;
  },

  updateFranchise: async (id: number, payload: Partial<FranchiseBranch>) => {
    const response = await apiClient.put<MoiApiResponse<{ message: string; franchise: FranchiseBranch }>>(
      `/franchises/super-admin/${id}`,
      payload
    );
    return response.data.responseValue;
  },

  updateFranchiseStatus: async (id: number, status: 'ACTIVE' | 'INACTIVE' | 'SUSPENDED') => {
    const response = await apiClient.patch<MoiApiResponse<{ message: string }>>(
      `/franchises/super-admin/${id}/status`,
      { status }
    );
    return response.data.responseValue;
  },

  assignFranchiseAdmin: async (franchiseId: number, adminId: number) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string }>>(
      `/franchises/super-admin/${franchiseId}/admins`,
      { adminId }
    );
    return response.data.responseValue;
  },

  removeFranchiseAdmin: async (franchiseId: number, adminId: number) => {
    const response = await apiClient.delete<MoiApiResponse<{ message: string }>>(
      `/franchises/super-admin/${franchiseId}/admins/${adminId}`
    );
    return response.data.responseValue;
  },

  // ==========================================
  // FRANCHISE ADMIN APIS
  // ==========================================
  getDashboard: async () => {
    const response = await apiClient.get<MoiApiResponse<FranchiseDashboardStats>>(
      '/franchises/admin/dashboard'
    );
    return response.data.responseValue;
  },

  listCustomers: async (params?: { limit?: number; offset?: number; search?: string }) => {
    const response = await apiClient.get<MoiApiResponse<{ customers: FranchiseCustomer[]; total: number }>>(
      '/franchises/admin/customers',
      { params }
    );
    return response.data.responseValue;
  },

  searchUsersForLinking: async (query: string) => {
    const response = await apiClient.get<MoiApiResponse<{ users: any[] }>>(
      '/franchises/admin/customers/search-user',
      { params: { query } }
    );
    return response.data.responseValue;
  },

  linkCustomer: async (userId: number, customerCode?: string) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string }>>(
      '/franchises/admin/customers/link-user',
      { userId, customerCode }
    );
    return response.data.responseValue;
  },

  createCustomerAccount: async (payload: { full_name: string; mobile: string; email?: string; password?: string }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string; customer: FranchiseCustomer }>>(
      '/franchises/admin/customers/create',
      payload
    );
    return response.data.responseValue;
  },

  updateCustomerStatus: async (userId: number, status: 'ACTIVE' | 'INACTIVE') => {
    const response = await apiClient.patch<MoiApiResponse<{ message: string }>>(
      `/franchises/admin/customers/${userId}/status`,
      { status }
    );
    return response.data.responseValue;
  },

  listStaff: async () => {
    const response = await apiClient.get<MoiApiResponse<{ staff: FranchiseStaff[] }>>(
      '/franchises/admin/staff'
    );
    return response.data.responseValue;
  },

  linkStaff: async (userId: number) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string }>>(
      '/franchises/admin/staff',
      { userId }
    );
    return response.data.responseValue;
  },

  createStaffAccount: async (payload: { full_name: string; mobile: string; email?: string; password?: string }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string; staff: FranchiseStaff }>>(
      '/franchises/admin/staff/create',
      payload
    );
    return response.data.responseValue;
  },

  updateStaffStatus: async (userId: number, status: 'ACTIVE' | 'INACTIVE') => {
    const response = await apiClient.patch<MoiApiResponse<{ message: string }>>(
      `/franchises/admin/staff/${userId}/status`,
      { status }
    );
    return response.data.responseValue;
  },

  listFunctions: async () => {
    const response = await apiClient.get<MoiApiResponse<{ functions: FranchiseFunction[] }>>(
      '/franchises/admin/functions'
    );
    return response.data.responseValue;
  },

  createFunction: async (payload: {
    name: string;
    function_date: string;
    location?: string;
    event_type?: string;
    customer_user_id?: number;
  }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string; function: FranchiseFunction }>>(
      '/franchises/admin/functions',
      payload
    );
    return response.data.responseValue;
  },

  setStaffPermissions: async (payload: {
    staffUserId: number;
    functionId: number;
    canView?: boolean;
    canAddCustomer?: boolean;
    canAddTransaction?: boolean;
    canEditTransaction?: boolean;
    canDeleteTransaction?: boolean;
    canViewReport?: boolean;
  }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string }>>(
      '/franchises/admin/staff-permissions',
      payload
    );
    return response.data.responseValue;
  },

  revokeStaffPermissions: async (staffUserId: number, functionId: number) => {
    const response = await apiClient.delete<MoiApiResponse<{ message: string }>>(
      '/franchises/admin/staff-permissions',
      { data: { staffUserId, functionId } }
    );
    return response.data.responseValue;
  },

  getReports: async (params?: { functionId?: number; startDate?: string; endDate?: string }) => {
    const response = await apiClient.get<MoiApiResponse<any>>(
      '/franchises/admin/reports',
      { params }
    );
    return response.data.responseValue;
  },

  getAuditLogs: async (params?: { limit?: number; offset?: number }) => {
    const response = await apiClient.get<MoiApiResponse<{ logs: FranchiseAuditLog[]; total: number }>>(
      '/franchises/admin/audit-logs',
      { params }
    );
    return response.data.responseValue;
  },

  // ==========================================
  // FRANCHISE STAFF APIS
  // ==========================================
  getAssignedFunctions: async () => {
    const response = await apiClient.get<MoiApiResponse<{ functions: FranchiseFunction[] }>>(
      '/franchises/staff/functions'
    );
    return response.data.responseValue;
  },

  getFunctionDetails: async (functionId: number) => {
    const response = await apiClient.get<MoiApiResponse<FranchiseFunction>>(
      `/franchises/staff/functions/${functionId}`
    );
    return response.data.responseValue;
  },

  getFunctionPersons: async (functionId: number) => {
    const response = await apiClient.get<MoiApiResponse<{ persons: any[] }>>(
      `/franchises/staff/functions/${functionId}/persons`
    );
    return response.data.responseValue;
  },

  addFunctionPerson: async (functionId: number, payload: { name: string; city?: string; mobile?: string }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string; person: any }>>(
      `/franchises/staff/functions/${functionId}/persons`,
      payload
    );
    return response.data.responseValue;
  },

  getFunctionTransactions: async (functionId: number) => {
    const response = await apiClient.get<MoiApiResponse<{ transactions: any[] }>>(
      `/franchises/staff/functions/${functionId}/transactions`
    );
    return response.data.responseValue;
  },

  addTransaction: async (functionId: number, payload: {
    person_id: number;
    amount: number;
    gift_item?: string;
    notes?: string;
    payment_type?: string;
  }) => {
    const response = await apiClient.post<MoiApiResponse<{ message: string; transaction: any }>>(
      `/franchises/staff/functions/${functionId}/transactions`,
      payload
    );
    return response.data.responseValue;
  },

  editTransaction: async (functionId: number, txId: number, payload: { amount?: number; gift_item?: string; notes?: string }) => {
    const response = await apiClient.put<MoiApiResponse<{ message: string }>>(
      `/franchises/staff/functions/${functionId}/transactions/${txId}`,
      payload
    );
    return response.data.responseValue;
  },

  deleteTransaction: async (functionId: number, txId: number) => {
    const response = await apiClient.delete<MoiApiResponse<{ message: string }>>(
      `/franchises/staff/functions/${functionId}/transactions/${txId}`
    );
    return response.data.responseValue;
  },

  getFunctionReport: async (functionId: number) => {
    const response = await apiClient.get<MoiApiResponse<any>>(
      `/franchises/staff/functions/${functionId}/reports`
    );
    return response.data.responseValue;
  },
};
