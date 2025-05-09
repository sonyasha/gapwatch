output "schedule_expression" {
  description = "The EventBridge schedule expression"
  value       = aws_cloudwatch_event_rule.daily_ingestion.schedule_expression
}

output "rule_arn" {
  description = "The ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.daily_ingestion.arn
}