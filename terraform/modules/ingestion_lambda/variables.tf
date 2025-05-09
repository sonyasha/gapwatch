variable "environment" {
  type        = string
  description = "Environment name"
}

variable "table_name" {
  type        = string
  description = "Name of the DynamoDB table"
}

variable "table_arn" {
  type        = string
  description = "ARN of the DynamoDB table"
}

variable "lambda_name" {
  type        = string
  description = "Name of the Lambda function"
}

variable "image_uri" {
  type        = string
  description = "ECR image URI for the Lambda container"
}

variable "news_api_key" {
  type        = string
  description = "API key for News API"
}