output "api_id" {
  value       = aws_apigatewayv2_api.this.id
  description = "The ID of the API Gateway HTTP API."
}

output "api_endpoint" {
  value       = aws_apigatewayv2_stage.this.invoke_url
  description = "The invoke URL of the deployed API Gateway stage."
}

output "execution_arn" {
  value       = aws_apigatewayv2_api.this.execution_arn
  description = "The execution ARN of the API Gateway HTTP API."
}
