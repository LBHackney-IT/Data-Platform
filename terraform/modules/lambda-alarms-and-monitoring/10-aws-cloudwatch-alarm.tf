resource "aws_sns_topic" "sns_topic" {
  name = "lambda-failure-notification-${var.lambda_name}"
}

data "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${var.lambda_name}"
}

resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  name           = "${var.lambda_name}-lambda-errors"
  pattern        = "ERROR"
  log_group_name = data.aws_cloudwatch_log_group.lambda_log_group.name

  metric_transformation {
    name          = "${var.lambda_name}-lambda-errors"
    namespace     = "DataPlatform"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_metric_alarm" {
  alarm_name          = aws_cloudwatch_log_metric_filter.metric_filter.name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.metric_filter.name
  namespace           = "DataPlatform"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  datapoints_to_alarm = "1"
  alarm_description   = "Triggers an alarm every time there's an error in the lambda's log stream within 5 minutes window"
  alarm_actions       = [aws_sns_topic.sns_topic.arn]
}

data "aws_lambda_function" "alarms_handler_lambda" {
  function_name = lower("${var.identifier_prefix}lambda-alarms-handler")
}

resource "aws_sns_topic_subscription" "topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint = data.aws_lambda_function.alarms_handler_lambda.arn
}

locals {
  lambda_name_upper_case = replace(title(replace(var.lambda_name, "-", " ")), " ", "")
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id = "Allow${local.lambda_name_upper_case}ExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.alarms_handler_lambda.function_name
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.sns_topic.arn
}
