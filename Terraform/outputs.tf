# output "ecr_repository_url" {
#   value       = module.ecr_module.repository_url
#   description = "The URL of the ECR repository"
# }

output "s3_bucket_for_file_storage" {
  value       = module.s3_bucket_for_file_storage.s3_bucket_name
  description = "The name of the S3 bucket for file storage"
}

output "lambda_backend_arn" {
  value       = module.lambda_backend.lambda_function_arn
  description = "The ARN of the Backend Lambda"
}

output "lambda_backend_function_url" {
  value       = module.lambda_backend.function_url
  description = "The HTTP Function URL of the Backend Lambda"
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
