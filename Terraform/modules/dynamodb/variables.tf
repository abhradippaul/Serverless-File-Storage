variable "name" {
  type        = string
  description = "The name of the DynamoDB table."
}

variable "hash_key" {
  type        = string
  description = "The partition key (hash key) of the DynamoDB table."
  default     = "user_id"
}

variable "range_key" {
  type        = string
  description = "The sort key (range key) of the DynamoDB table."
  default     = "file_id"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the DynamoDB table."
  default     = {}
}
