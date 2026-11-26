variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket."
  default     = {}
}

variable "creation_sqs_queue_arn" {
  type        = string
  description = "The ARN of the SQS queue for object creation events."
}

variable "deletion_sqs_queue_arn" {
  type        = string
  description = "The ARN of the SQS queue for object deletion events."
}
