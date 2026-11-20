variable "ecr_repository_name" {
  type        = string
  description = "The name of the ECR repository."
}

variable "tags" {
  type        = map(string)
  description = "The tags to apply to the ECR repository."
}
