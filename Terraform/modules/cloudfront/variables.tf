variable "frontend_bucket_id" {
  type        = string
  description = "The ID/name of the frontend S3 bucket"
}

variable "frontend_bucket_arn" {
  type        = string
  description = "The ARN of the frontend S3 bucket"
}

variable "frontend_bucket_regional_domain_name" {
  type        = string
  description = "The regional domain name of the frontend S3 bucket"
}

variable "frontend_bucket_origin_id" {
  type        = string
  description = "The origin ID for the frontend S3 bucket"
  default     = "frontend-s3-origin"
}

variable "comment" {
  type        = string
  description = "Comment for the CloudFront distribution"
  default     = "CloudFront distribution for frontend S3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to CloudFront resources"
  default     = {}
}

variable "enabled" {
  type        = bool
  description = "Enable CloudFront distribution"
}
