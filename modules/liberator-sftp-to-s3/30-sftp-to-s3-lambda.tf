resource "aws_lambda_function" "liberator_data_upload_lambda" {
  tags = var.tags

  role             = aws_iam_role.liberator_data_upload_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${var.identifier_prefix}-liberator-data-upload"
  s3_bucket        = var.lambda_artefact_storage_bucket_name
  s3_key           = aws_s3_bucket_object.liberator_data_upload_lambda.key
  source_code_hash = data.archive_file.liberator_data_upload_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      SFTP_HOST         = local.liberator_data_sftp_server_host.value
      SFTP_USERNAME     = local.liberator_data_sftp_server_username.value
      SFTP_PASSWORD     = local.liberator_data_sftp_server_password.value
      S3_BUCKET         = var.s3_bucket_id
      OBJECT_KEY_PREFIX = "parking/"
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_day_every_half_hour_between_three_and_six_am" {
  name                = "${var.identifier_prefix}-every-day-every-half-hour-between-three-and-six-am"
  description         = "Runs every day, every half-hour between 3am and 6.30am inclusive"
  schedule_expression = "cron(0,30 03-06 * * ? *)"
  is_enabled          = var.run_daily
}

resource "aws_cloudwatch_event_target" "run_liberator_uploader_every_day" {
  rule      = aws_cloudwatch_event_rule.every_day_every_half_hour_between_three_and_six_am.name
  target_id = aws_lambda_function.liberator_data_upload_lambda.function_name
  arn       = aws_lambda_function.liberator_data_upload_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_liberator_data_upload_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.liberator_data_upload_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_every_half_hour_between_three_and_six_am.arn
}
