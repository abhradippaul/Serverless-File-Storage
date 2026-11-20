import dotenv from 'dotenv';
if (!process.env.AWS_LAMBDA_FUNCTION_NAME) {
  dotenv.config();
}

import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  type S3ClientConfig,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { v4 as uuidv4 } from 'uuid';

export function getRegion(): string {
  return process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION || 'ap-south-1';
}

export function getBucketName(): string {
  const bucket =
    process.env.FILE_STORAGE_BUCKET_NAME ||
    process.env.AWS_BUCKET_NAME ||
    'file-storage-aws-bucket';

  if (!bucket) {
    throw new Error('Bucket name is missing. Please set FILE_STORAGE_BUCKET_NAME or AWS_BUCKET_NAME.');
  }

  return bucket;
}

const clientConfig: S3ClientConfig = {
  region: getRegion(),
};

// Use explicit credentials if provided, otherwise AWS SDK default credential chain
if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
  clientConfig.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    sessionToken: process.env.AWS_SESSION_TOKEN || undefined,
  };
}

export const s3Client = new S3Client(clientConfig);

export interface PresignedUploadOptions {
  fileName: string;
  fileType: string;
  userId?: string;
  expiresInSeconds?: number;
}

export interface PresignedDownloadOptions {
  key: string;
  originalName?: string;
  expiresInSeconds?: number;
}

/**
 * Generates an S3 presigned URL for direct client-side PUT upload.
 */
export async function getPresignedUploadUrl(options: PresignedUploadOptions) {
  const { fileName, fileType, userId = 'anonymous', expiresInSeconds = 3600 } = options;

  if (!fileName) {
    throw new Error('fileName is required');
  }

  const bucket = getBucketName();
  const region = getRegion();

  // Clean filename to prevent path traversal or problematic characters
  const cleanFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  const uniqueId = uuidv4();
  const key = `uploads/${userId}/${Date.now()}-${uniqueId}-${cleanFileName}`;

  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: fileType || 'application/octet-stream',
    Metadata: {
      'original-filename': encodeURIComponent(fileName),
      'user-id': userId,
    },
  });

  const uploadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: expiresInSeconds,
  });

  return {
    uploadUrl,
    key,
    bucket,
    region,
    expiresIn: expiresInSeconds,
  };
}

/**
 * Generates an S3 presigned URL for secure client-side GET download/view.
 */
export async function getPresignedDownloadUrl(options: PresignedDownloadOptions) {
  const { key, originalName, expiresInSeconds = 3600 } = options;

  if (!key) {
    throw new Error('key is required');
  }

  const bucket = getBucketName();

  const command = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
    ResponseContentDisposition: originalName
      ? `attachment; filename="${encodeURIComponent(originalName)}"`
      : undefined,
  });

  const downloadUrl = await getSignedUrl(s3Client, command, {
    expiresIn: expiresInSeconds,
  });

  return {
    downloadUrl,
    key,
    expiresIn: expiresInSeconds,
  };
}

/**
 * Deletes an object from S3.
 */
export async function deleteS3Object(key: string) {
  if (!key) {
    throw new Error('key is required');
  }

  const bucket = getBucketName();

  const command = new DeleteObjectCommand({
    Bucket: bucket,
    Key: key,
  });

  await s3Client.send(command);

  return {
    success: true,
    key,
  };
}

export function getS3Config() {
  return {
    bucket: getBucketName(),
    region: getRegion(),
    hasConfiguredCredentials: Boolean(
      process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY
    ),
  };
}
