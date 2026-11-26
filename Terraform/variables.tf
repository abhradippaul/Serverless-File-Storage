variable "aws_region" {
  type        = string
  description = "The AWS region to deploy the resources in."
  default     = "ap-south-1"
}

variable "aws_profile" {
  type        = string
  description = "The AWS profile to use."
  default     = "pa-abhradip"
}

variable "file_storage_bucket_name" {
  type        = string
  description = "The name of the S3 bucket."
  default     = "file-storage-aws-bucket"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket."
  default = {
    Name        = "File-Storage-AWS"
    Environment = "Dev"
    Project     = "File-Storage-AWS"
  }
}

variable "frontend_bucket_name" {
  type        = string
  description = "The name of the S3 bucket."
  default     = "file-storage-aws-frontend"
}

variable "source_path" {
  type        = string
  description = "Path to the source code (directory containing Dockerfile)."
  default     = "../Frontend"
}

variable "enable_function_url" {
  type        = bool
  description = "Enable Lambda Function URL for HTTP access"
  default     = true
}

variable "file_storage_backend_lambda_name" {
  type        = string
  description = "The name of the Lambda function."
  default     = "file-storage-aws-backend-lambda"
}

variable "backend_source_path" {
  type        = string
  description = "Path to the source code (directory containing Dockerfile)."
  default     = "../Backend"
}

variable "frontend_source_path" {
  type        = string
  description = "Path to the source code (directory containing Dockerfile)."
  default     = "../Frontend"
}

variable "backend_lambda_handler" {
  type        = string
  description = "The handler for the Lambda function."
  default     = "index.handler"
}

variable "backend_lambda_runtime" {
  type        = string
  description = "The runtime for the Lambda function."
  default     = "nodejs24.x"
}

variable "backend_lambda_architecture" {
  type        = string
  description = "The architecture for the Lambda function."
  default     = "arm64"
}

variable "backend_lambda_memory_size" {
  type        = number
  description = "The memory size of the Lambda function."
  default     = 128
}

variable "backend_lambda_timeout" {
  type        = number
  description = "The timeout for the Lambda function."
  default     = 30
}

variable "api_gateway_name" {
  type        = string
  description = "The name of the API Gateway HTTP API."
  default     = "file-storage-aws-api"
}

variable "enable_cloudfront" {
  type        = bool
  description = "Enable CloudFront distribution"
  default     = true
}

variable "creation_sqs_queue_name" {
  type        = string
  description = "The name of the SQS queue for S3 object creation events."
  default     = "file-storage-aws-creation-queue"
}

variable "deletion_sqs_queue_name" {
  type        = string
  description = "The name of the SQS queue for S3 object deletion events."
  default     = "file-storage-aws-deletion-queue"
}

variable "sqs_delay_seconds" {
  type        = number
  description = "The time in seconds that the delivery of all messages in the queue will be delayed."
  default     = 0
}

variable "sqs_max_message_size" {
  type        = number
  description = "The limit of how many bytes a message can contain before Amazon SQS rejects it."
  default     = 262144
}

variable "sqs_message_retention_seconds" {
  type        = number
  description = "The number of seconds Amazon SQS retains a message."
  default     = 345600
}

variable "sqs_receive_wait_time_seconds" {
  type        = number
  description = "The time for which a ReceiveMessage call will wait for a message to arrive."
  default     = 0
}

variable "sqs_visibility_timeout_seconds" {
  type        = number
  description = "The visibility timeout for the queue in seconds."
  default     = 30
}

variable "metadata_processor_creation_lambda_name" {
  type        = string
  description = "The name of the Metadata Processor Creation Lambda function."
  default     = "file-storage-aws-metadata-processor-creation-lambda"
}

variable "metadata_processor_creation_source_path" {
  type        = string
  description = "Path to the Metadata Processor Creation source code directory."
  default     = "../Metadata-Processor-Creation"
}

variable "metadata_processor_deletion_lambda_name" {
  type        = string
  description = "The name of the Metadata Processor Deletion Lambda function."
  default     = "file-storage-aws-metadata-processor-deletion-lambda"
}

variable "metadata_processor_deletion_source_path" {
  type        = string
  description = "Path to the Metadata Processor Deletion source code directory."
  default     = "../Metadata-Processor-Deletion"
}

variable "metadata_processor_lambda_handler" {
  type        = string
  description = "The handler for the Metadata Processor Lambda function."
  default     = "main.handler"
}

variable "metadata_processor_lambda_runtime" {
  type        = string
  description = "The runtime for the Metadata Processor Lambda function."
  default     = "python3.13"
}

variable "metadata_processor_lambda_architecture" {
  type        = string
  description = "The architecture for the Metadata Processor Lambda function."
  default     = "arm64"
}

variable "metadata_processor_lambda_memory_size" {
  type        = number
  description = "The memory size of the Metadata Processor Lambda function."
  default     = 128
}

variable "metadata_processor_lambda_timeout" {
  type        = number
  description = "The timeout for the Metadata Processor Lambda function."
  default     = 30
}

variable "metadata_dynamodb_table_name" {
  type        = string
  description = "The name of the DynamoDB table storing file metadata."
  default     = "drive-files-metadata"
}
