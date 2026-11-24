output "lambda_function_name" {
  value       = aws_lambda_function.this.function_name
  description = "The name of the Lambda function."
}

output "lambda_function_arn" {
  value       = aws_lambda_function.this.arn
  description = "The ARN of the Lambda function."
}

output "lambda_invoke_arn" {
  value       = aws_lambda_function.this.invoke_arn
  description = "The invoke ARN of the Lambda function (used by API Gateway integrations)."
}

output "function_url" {
  value       = var.enable_function_url ? aws_lambda_function_url.this[0].function_url : null
  description = "The HTTP Function URL of the Lambda function."
}
