resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  name           = "${var.lambda_name}-lambda-errors"
  pattern        = "ERROR"
  log_group_name = "/aws/lambda/${var.lambda_name}"

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
  alarm_description   = "Triggers an alarm every time there's an error in the lambda's log stream"
  alarm_actions       = [aws_sns_topic.sns_topic.arn]
}
