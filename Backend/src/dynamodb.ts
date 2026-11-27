import dotenv from 'dotenv';
if (!process.env.AWS_LAMBDA_FUNCTION_NAME) {
  dotenv.config();
}

import { DynamoDBClient, type DynamoDBClientConfig } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { getRegion } from './s3.js';

const clientConfig: DynamoDBClientConfig = {
  region: getRegion(),
};

if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
  clientConfig.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    sessionToken: process.env.AWS_SESSION_TOKEN || undefined,
  };
}

const ddbClient = new DynamoDBClient(clientConfig);
export const docClient = DynamoDBDocumentClient.from(ddbClient);

export function getMetadataTableName(): string {
  return process.env.DYNAMODB_TABLE_NAME || 'drive-files-metadata';
}

export interface FileMetadataRecord {
  id: string;
  name: string;
  size: number;
  type: string;
  key: string;
  uploadedAt: string;
  status: 'completed';
}

/**
 * Lists uploaded files for a user from the DynamoDB metadata table.
 */
export async function listUserFiles(userId: string): Promise<FileMetadataRecord[]> {
  const tableName = getMetadataTableName();

  const response = await docClient.send(
    new QueryCommand({
      TableName: tableName,
      KeyConditionExpression: 'user_id = :userId',
      ExpressionAttributeValues: {
        ':userId': userId,
      },
    })
  );

  const items = response.Items ?? [];

  return items
    .map((item) => ({
      id: String(item.file_id),
      name: String(item.file_name || ''),
      size: Number(item.file_size || 0),
      type: String(item.content_type || 'application/octet-stream'),
      key: String(item.s3_key || ''),
      uploadedAt: String(item.created_at || item.updated_at || new Date().toISOString()),
      status: 'completed' as const,
    }))
    .sort((a, b) => new Date(b.uploadedAt).getTime() - new Date(a.uploadedAt).getTime());
}
