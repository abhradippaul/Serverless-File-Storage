output "distribution_id" {
  value       = aws_cloudfront_distribution.s3_distribution.id
  description = "The identifier for the CloudFront distribution"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.s3_distribution.arn
  description = "The ARN of the CloudFront distribution"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "The domain name corresponding to the distribution"
}

output "distribution_hosted_zone_id" {
  value       = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
  description = "The CloudFront Route 53 zone ID"
}
