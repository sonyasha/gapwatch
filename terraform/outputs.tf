output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "lambda_function_name" {
  value = module.ingestion_lambda.lambda_name
}

output "cloudwatch_schedule" {
  description = "The EventBridge schedule expression"
  value       = module.eventbridge.schedule_expression
}