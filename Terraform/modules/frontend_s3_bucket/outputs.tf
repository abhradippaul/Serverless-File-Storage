output "s3_bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "ARN of the S3 bucket"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Name of the S3 bucket"
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
  description = "The website endpoint URL for the S3 bucket"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "The regional domain name of the S3 bucket"
}

output "bucket_origin_id" {
  value       = aws_s3_bucket.this.id
  description = "The origin ID of the S3 bucket"
}
