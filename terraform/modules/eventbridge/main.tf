resource "aws_cloudwatch_event_rule" "daily_ingestion" {
  name                = "daily_ingestion"
  schedule_expression = var.schedule_expr
}

resource "aws_cloudwatch_event_target" "trigger_ingestion" {
  rule      = aws_cloudwatch_event_rule.daily_ingestion.name
  target_id = "IngestionLambda"
  arn       = var.lambda_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_ingestion.arn
}
