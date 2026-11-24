variable "api_name" {
  type        = string
  description = "The name of the API Gateway HTTP API."
}

variable "lambda_invoke_arn" {
  type        = string
  description = "The invoke ARN of the Lambda function to integrate with API Gateway."
}

variable "lambda_function_name" {
  type        = string
  description = "The name of the Lambda function (used to grant API Gateway invoke permission)."
}

variable "stage_name" {
  type        = string
  description = "The name of the API Gateway stage to deploy."
  default     = "$default"
}

variable "route_key" {
  type        = string
  description = "The route key for the API Gateway route (e.g. 'ANY /{proxy+}')."
  default     = "ANY /{proxy+}"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all API Gateway resources."
  default     = {}
}
