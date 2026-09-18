import { apiClient } from "@/lib/axios";

export interface MoiApiResponse<T> {
  responseType: "S" | "E" | "F" | string;
  responseValue: T;
  responseMessage?: string;
}

export interface BackupFile {
  filename: string;
  size: number;
  createdAt: string;
}

export interface BackupListResult {
  database?: string;
  count: number;
  files: BackupFile[];
}

function extractErrorMessage(data: MoiApiResponse<unknown>): string {
  const value = data.responseValue;
  if (value && typeof value === "object" && "message" in value) {
    return String((value as { message: string }).message);
  }
  if (typeof value === "string") return value;
  return data.responseMessage || "Request failed";
}

function assertSuccess<T>(data: MoiApiResponse<T>): T {
  if (data.responseType !== "S") {
    throw new Error(extractErrorMessage(data));
  }
  return data.responseValue;
}

function filenameFromDisposition(header?: string): string | null {
  if (!header) return null;
  const utfMatch = header.match(/filename\*=UTF-8''([^;]+)/i);
  if (utfMatch?.[1]) return decodeURIComponent(utfMatch[1]);
  const match = header.match(/filename="?([^"]+)"?/i);
  return match?.[1] || null;
}

async function triggerDownload(blob: Blob, filename: string) {
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.URL.revokeObjectURL(url);
}

async function parseBlobError(blob: Blob): Promise<string> {
  try {
    const text = await blob.text();
    const data = JSON.parse(text) as MoiApiResponse<unknown>;
    return extractErrorMessage(data);
  } catch {
    return "Backup download failed.";
  }
}

async function saveAxiosFile(
  response: {
    data: Blob;
    headers: Record<string, string>;
    status: number;
  },
  fallbackName: string
) {
  const blob = response.data;
  const contentType = String(response.headers["content-type"] || "");
  if (contentType.includes("application/json") || blob.type.includes("application/json")) {
    throw new Error(await parseBlobError(blob));
  }
  const filename =
    filenameFromDisposition(response.headers["content-disposition"]) || fallbackName;
  await triggerDownload(blob, filename);
}

async function unwrapBlobRequest<T>(fn: () => Promise<T>): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    const axiosError = error as {
      response?: { data?: Blob | string };
      message?: string;
    };
    const data = axiosError.response?.data;
    if (data instanceof Blob) {
      throw new Error(await parseBlobError(data));
    }
    if (typeof data === "string" && data.trim()) {
      try {
        const parsed = JSON.parse(data) as MoiApiResponse<unknown>;
        throw new Error(extractErrorMessage(parsed));
      } catch (inner) {
        if (inner instanceof Error && inner.message !== data) throw inner;
      }
    }
    throw error instanceof Error ? error : new Error("Backup request failed.");
  }
}

export const backupApi = {
  list: async (): Promise<BackupListResult> => {
    const response = await apiClient.get<MoiApiResponse<BackupListResult>>(
      "/admin/database/backups"
    );
    return assertSuccess(response.data);
  },

  createAndDownload: async (): Promise<void> => {
    await unwrapBlobRequest(async () => {
      const response = await apiClient.post(
        "/admin/database/backup",
        {},
        {
          responseType: "blob",
          timeout: 5 * 60 * 1000,
          skipErrorHandler: true,
          skipLoading: true,
        }
      );
      await saveAxiosFile(
        response,
        `moi-kanakku-${new Date().toISOString().slice(0, 19).replace(/[:T]/g, "")}.sql.gz`
      );
    });
  },

  download: async (filename: string): Promise<void> => {
    await unwrapBlobRequest(async () => {
      const response = await apiClient.get(
        `/admin/database/backups/${encodeURIComponent(filename)}`,
        {
          responseType: "blob",
          timeout: 5 * 60 * 1000,
          skipErrorHandler: true,
          skipLoading: true,
        }
      );
      await saveAxiosFile(response, filename);
    });
  },

  remove: async (filename: string): Promise<void> => {
    const response = await apiClient.delete<MoiApiResponse<{ message?: string }>>(
      `/admin/database/backups/${encodeURIComponent(filename)}`
    );
    assertSuccess(response.data);
  },
};
