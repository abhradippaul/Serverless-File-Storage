import type {
  UploadedFile,
  PresignedUploadResponse,
  PresignedDownloadResponse,
  S3ConfigResponse,
} from '../types';

const USER_ID_KEY = 'serverless_storage_user_id';
const API_BASE_URL = (import.meta.env.VITE_API_URL || '').replace(/\/+$/, '');

/**
 * Returns existing persistent anonymous user ID or creates a new one.
 */
export function getOrCreateUserId(): string {
  let userId = localStorage.getItem(USER_ID_KEY);
  if (!userId) {
    // Generate UUID or timestamp-based random ID
    if (typeof crypto !== 'undefined' && crypto.randomUUID) {
      userId = `user_${crypto.randomUUID().slice(0, 8)}`;
    } else {
      userId = `user_${Math.random().toString(36).substring(2, 10)}`;
    }
    localStorage.setItem(USER_ID_KEY, userId);
  }
  return userId;
}

/**
 * Fetches uploaded files for a user from the backend (DynamoDB).
 */
export async function fetchUserFiles(userId: string): Promise<UploadedFile[]> {
  const response = await fetch(
    `${API_BASE_URL}/api/files?userId=${encodeURIComponent(userId)}`
  );
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.details || data.error || `Failed to fetch files (${response.status})`);
  }
  const data = await response.json();
  return Array.isArray(data.files) ? data.files : [];
}

/**
 * Fetches S3 and server config status.
 */
export async function fetchServerConfig(): Promise<S3ConfigResponse> {
  const response = await fetch(`${API_BASE_URL}/api/config`);
  if (!response.ok) {
    throw new Error(`Failed to fetch config (${response.status})`);
  }
  return response.json();
}

/**
 * Requests an S3 presigned PUT URL from the backend.
 */
export async function getPresignedUploadUrl(
  fileName: string,
  fileType: string,
  userId: string
): Promise<PresignedUploadResponse> {
  const response = await fetch(`${API_BASE_URL}/api/files/upload-url`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fileName,
      fileType,
      userId,
    }),
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.details || data.error || `Server responded with ${response.status}`);
  }

  return response.json();
}

/**
 * Directly uploads file to S3 using the presigned URL with progress tracking.
 */
export function uploadToS3Direct(
  uploadUrl: string,
  file: File,
  onProgress: (percent: number) => void
): Promise<void> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();

    xhr.open('PUT', uploadUrl, true);
    xhr.setRequestHeader('Content-Type', file.type || 'application/octet-stream');

    xhr.upload.onprogress = (event) => {
      if (event.lengthComputable) {
        const percent = Math.round((event.loaded / event.total) * 100);
        onProgress(percent);
      }
    };

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve();
      } else {
        reject(
          new Error(
            `S3 upload failed with HTTP ${xhr.status}: ${xhr.statusText || 'Check bucket CORS and credentials'}`
          )
        );
      }
    };

    xhr.onerror = () => {
      reject(
        new Error(
          'Network or CORS error uploading directly to S3. Ensure S3 CORS permits PUT from this origin.'
        )
      );
    };

    xhr.ontimeout = () => {
      reject(new Error('S3 upload timed out'));
    };

    xhr.send(file);
  });
}

/**
 * Requests an S3 presigned GET URL to download or view a file.
 */
export async function getPresignedDownloadUrl(
  key: string,
  originalName: string
): Promise<PresignedDownloadResponse> {
  const response = await fetch(`${API_BASE_URL}/api/files/download-url`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      key,
      originalName,
    }),
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.details || data.error || `Failed to get download URL`);
  }

  return response.json();
}

/**
 * Requests backend to delete a file from S3.
 */
export async function deleteS3File(key: string): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/api/files?key=${encodeURIComponent(key)}`, {
    method: 'DELETE',
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.details || data.error || `Failed to delete file`);
  }
}
