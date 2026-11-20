export interface UploadedFile {
  id: string;
  name: string;
  size: number;
  type: string;
  key: string;
  uploadedAt: string;
  status: 'uploading' | 'completed' | 'failed';
  progress?: number;
  downloadUrl?: string;
  error?: string;
}

export interface PresignedUploadResponse {
  uploadUrl: string;
  key: string;
  bucket: string;
  region: string;
  expiresIn: number;
}

export interface PresignedDownloadResponse {
  downloadUrl: string;
  key: string;
  expiresIn: number;
}

export interface S3ConfigResponse {
  bucket: string;
  region: string;
  hasConfiguredCredentials: boolean;
}
