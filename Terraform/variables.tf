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
