resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${local.lambda_name_underscore}-schedule"
  description         = "Schedule for triggering lambda ${var.function_name}"
  schedule_expression = var.schedule
  event_pattern       = var.event_pattern
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "Invoke${var.function_name}Lambda"
  arn       = aws_lambda_function.lambda.arn
  input     = var.event_input
}

resource "aws_lambda_permission" "allow_events_bridge_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
}
