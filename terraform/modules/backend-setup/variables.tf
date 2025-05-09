variable "aws_region" {
  default = "us-west-1"
}

variable "bucket_name" {
  description = "S3 bucket name for Terraform state"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
}

variable "environment" {
  default = "prod"
}