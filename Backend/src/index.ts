import dotenv from 'dotenv';
if (!process.env.AWS_LAMBDA_FUNCTION_NAME) {
  dotenv.config();
}

import express, { type Request, type Response } from 'express';
import cors from 'cors';
import serverless from 'serverless-http';
import {
  getPresignedUploadUrl,
  getPresignedDownloadUrl,
  deleteS3Object,
  getS3Config,
} from './s3.js';

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Informational routes
app.get(['/', '/home'], (_req: Request, res: Response) => {
  res.status(200).json({
    name: 'Serverless File Storage API',
    message: 'Welcome to the Serverless File Storage API',
    status: 'running',
    endpoints: {
      home: '/',
      health: '/health',
      s3Config: '/api/config',
      getUploadUrl: 'POST /api/files/upload-url',
      getDownloadUrl: 'POST /api/files/download-url',
      deleteFile: 'DELETE /api/files',
    },
  });
});

app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'healthy',
    uptime: `${Math.floor(process.uptime())}s`,
    timestamp: new Date().toISOString(),
  });
});

// S3 Configuration info (safe, no secrets)
app.get('/api/config', (_req: Request, res: Response) => {
  res.status(200).json(getS3Config());
});

/**
 * Generate Presigned Upload URL
 * Body: { fileName: string, fileType: string, userId?: string }
 */
app.post('/api/files/upload-url', async (req: Request, res: Response) => {
  try {
    const { fileName, fileType, userId } = req.body;

    if (!fileName) {
      return res.status(400).json({ error: 'fileName is required' });
    }

    const result = await getPresignedUploadUrl({
      fileName,
      fileType: fileType || 'application/octet-stream',
      userId: userId || 'anonymous',
    });

    res.status(200).json(result);
  } catch (error: any) {
    console.error('Error generating presigned upload URL:', error);
    res.status(500).json({
      error: 'Failed to generate upload URL',
      details: error.message || 'Internal server error',
    });
  }
});

/**
 * Generate Presigned Download/View URL
 * Body: { key: string, originalName?: string } or Query: ?key=...&originalName=...
 */
app.all('/api/files/download-url', async (req: Request, res: Response) => {
  try {
    const key = (req.body?.key || req.query?.key) as string;
    const originalName = (req.body?.originalName || req.query?.originalName) as string | undefined;

    if (!key) {
      return res.status(400).json({ error: 'key is required' });
    }

    const result = await getPresignedDownloadUrl({
      key,
      originalName,
    });

    res.status(200).json(result);
  } catch (error: any) {
    console.error('Error generating presigned download URL:', error);
    res.status(500).json({
      error: 'Failed to generate download URL',
      details: error.message || 'Internal server error',
    });
  }
});

/**
 * Delete file from S3
 * Query or Body: key
 */
app.delete('/api/files', async (req: Request, res: Response) => {
  try {
    const key = (req.query.key || req.body?.key) as string;

    if (!key) {
      return res.status(400).json({ error: 'key is required' });
    }

    const result = await deleteS3Object(key);
    res.status(200).json({
      success: true,
      message: 'File deleted successfully',
      key: result.key,
    });
  } catch (error: any) {
    console.error('Error deleting S3 object:', error);
    res.status(500).json({
      error: 'Failed to delete file',
      details: error.message || 'Internal server error',
    });
  }
});

// 404 Handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Export handler for AWS Lambda
export const handler = serverless(app);

// Start server locally when not running in AWS Lambda
if (!process.env.AWS_LAMBDA_FUNCTION_NAME) {
  app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
  });
}
