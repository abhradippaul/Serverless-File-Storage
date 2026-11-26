variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket."
}

variable "source_path" {
  type        = string
  description = "Path to the Frontend project directory (defaults to ../Frontend relative to root)."
  default     = ""
}

variable "aws_profile" {
  type        = string
  description = "The AWS CLI profile to use."
}

variable "api_url" {
  type        = string
  description = "Base URL of the backend API Gateway endpoint."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the S3 bucket."
  default     = {}
}
