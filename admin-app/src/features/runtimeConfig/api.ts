import { apiClient } from '@/lib/axios';

type MoiApiResponse<T> = {
  responseType: string;
  responseValue: T;
  responseMessage?: string;
};

export interface RuntimeConfig {
  liveURL: string;
  imageUrl: string;
  maintenanceMode: boolean;
  minAppVersion: string;
  updatedAt?: string | null;
}

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (String(data.responseType).toUpperCase() !== 'S') {
    throw new Error(data.responseMessage || 'Request failed');
  }
  return data.responseValue;
}

export const runtimeConfigApi = {
  get: async (): Promise<RuntimeConfig> => {
    const response = await apiClient.get<MoiApiResponse<RuntimeConfig>>('/app-config/admin');
    return assertSuccess(response.data);
  },
  update: async (config: RuntimeConfig): Promise<RuntimeConfig> => {
    const response = await apiClient.put<MoiApiResponse<RuntimeConfig>>(
      '/app-config/admin',
      config,
    );
    return assertSuccess(response.data);
  },
};
