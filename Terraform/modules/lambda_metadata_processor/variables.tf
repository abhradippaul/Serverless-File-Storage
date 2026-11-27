variable "function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "source_path" {
  type        = string
  description = "The path to the Metadata-Processor source code directory."
}

variable "handler" {
  type        = string
  description = "The handler of the Lambda function."
  default     = "main.handler"
}

variable "runtime" {
  type        = string
  description = "The runtime of the Lambda function."
  default     = "python3.13"
}

variable "architecture" {
  type        = string
  description = "The architecture of the Lambda function (arm64 or x86_64)."
  default     = "arm64"
}

variable "memory_size" {
  type        = number
  description = "The memory size of the Lambda function in MB."
  default     = 128
}

variable "timeout" {
  type        = number
  description = "The timeout of the Lambda function in seconds."
  default     = 30
}

variable "log_retention_days" {
  type        = number
  description = "The number of days to retain CloudWatch logs."
  default     = 14
}

variable "s3_bucket_arn" {
  type        = string
  description = "Optional ARN of the S3 bucket for metadata processing."
  default     = null
}

variable "sqs_arn" {
  type        = string
  description = "ARN of the SQS queue for metadata processing."
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN of the DynamoDB table for file metadata."
}

variable "environment_variables" {
  type        = map(string)
  description = "The environment variables of the Lambda function."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
