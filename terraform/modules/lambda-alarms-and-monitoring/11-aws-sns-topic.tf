resource "aws_sns_topic" "sns_topic" {
  name = "lambda-failure-notification-${var.lambda_name}"
  kms_master_key_id = aws_kms_key.lambda_failure_notifications_kms_key.id
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
