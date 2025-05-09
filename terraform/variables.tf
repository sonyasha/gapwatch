variable "aws_region" {
  description = "AWS region to deploy resources into"
  default     = "us-west-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  default     = "prod"
}

variable "table_name" {
  description = "Name of the DynamoDB table"
  default     = "gapwatch_articles"
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
  description = "API key for News API"
  type        = string
}