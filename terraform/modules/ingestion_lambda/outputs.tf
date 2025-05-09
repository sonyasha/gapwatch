output "lambda_name" {
  value = aws_lambda_function.ingestion.function_name
}

output "lambda_arn" {
  description = "Full ARN of the deployed Lambda function"
  value       = aws_lambda_function.ingestion.arn
}
