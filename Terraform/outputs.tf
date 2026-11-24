# output "ecr_repository_url" {
#   value       = module.ecr_module.repository_url
#   description = "The URL of the ECR repository"
# }

output "s3_bucket_for_file_storage" {
  value       = module.s3_bucket_for_file_storage.s3_bucket_name
  description = "The name of the S3 bucket for file storage"
}

output "frontend_website_url" {
  value       = "http://${module.s3_bucket_for_frontend_storage.website_endpoint}"
  description = "The static website hosting URL"
}

# output "cloudfront_domain_name" {
#   value       = module.cloudfront.distribution_domain_name
#   description = "The domain name of the CloudFront distribution"
# }

# output "cloudfront_distribution_id" {
#   value       = module.cloudfront.distribution_id
#   description = "The ID of the CloudFront distribution"
# }

output "lambda_backend_arn" {
  value       = module.lambda_backend.lambda_function_arn
  description = "The ARN of the Backend Lambda"
}

output "lambda_backend_function_url" {
  value       = module.lambda_backend.function_url
  description = "The HTTP Function URL of the Backend Lambda"
}

output "api_gateway_endpoint" {
  value       = module.apigateway.api_endpoint
  description = "The invoke URL of the API Gateway stage"
}

# output "sqs_queue_url" {
#   value       = module.sqs_module.sqs_queue_url
#   description = "The URL of the SQS queue"
# }

# output "lambda_dispatcher_arn" {
#   value       = module.lambda_module_dispatcher.lambda_function_arn
#   description = "The ARN of the Dispatcher Lambda"
# }

# output "lambda_worker_arn" {
#   value       = module.lambda_module_worker.lambda_function_arn
#   description = "The ARN of the Worker Lambda"
# }
