terraform {
  backend "s3" {
    bucket         = "gapwatch-terraform-state-bucket-2025"
    key            = "gapwatch/prod/terraform.tfstate"
    region         = "us-west-1"
    dynamodb_table = "gapwatch-terraform-locks-table"
    encrypt        = true
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  table_name  = var.table_name
  environment = var.environment
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = "gapwatch-ingestion"
  environment     = var.environment
}

module "ingestion_lambda" {
  source       = "./modules/ingestion_lambda"
  lambda_name  = var.lambda_name
  environment  = var.environment
  table_name   = module.dynamodb.table_name
  table_arn    = module.dynamodb.table_arn
  image_uri    = var.image_uri
  news_api_key = var.news_api_key
}

module "eventbridge" {
  source        = "./modules/eventbridge"
  lambda_arn    = module.ingestion_lambda.lambda_arn
  lambda_name   = module.ingestion_lambda.lambda_name
  schedule_expr = "rate(1 day)"
}