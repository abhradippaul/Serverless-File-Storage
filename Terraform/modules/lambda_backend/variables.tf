variable "function_name" {
  type        = string
  description = "The name of the Lambda function."
}

variable "source_path" {
  type        = string
  description = "The path to the Backend source code directory."
}

variable "handler" {
  type        = string
  description = "The handler of the Lambda function."
  default     = "index.handler"
}

variable "runtime" {
  type        = string
  description = "The runtime of the Lambda function."
  default     = "nodejs24.x"
}

variable "architecture" {
  type        = string
  description = "The architecture of the Lambda function (arm64 or x86_64)."
  default     = "arm64"
}

variable "memory_size" {
  type        = number
  description = "The memory size of the Lambda function in MB."
  default     = 256
}

variable "timeout" {
  type        = number
  description = "The timeout of the Lambda function in seconds."
  default     = 30
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

variable "log_retention_days" {
  type        = number
  description = "The number of days to retain CloudWatch logs."
  default     = 14
}

variable "s3_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket for file storage."
}

variable "sqs_arn" {
  type        = string
  description = "The ARN of an SQS queue (optional)."
  default     = ""
}

variable "ephemeral_storage" {
  type        = number
  description = "The ephemeral storage size of the Lambda function in MB."
  default     = 512
}

variable "enable_function_url" {
  type        = bool
  description = "Whether to create a public Lambda Function URL for HTTP API access."
  default     = true
}
