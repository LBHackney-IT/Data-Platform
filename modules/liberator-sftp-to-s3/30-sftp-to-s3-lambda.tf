resource "aws_lambda_function" "parking_liberator_data_upload_lambda" {
  tags = var.tags

  role             = aws_iam_role.parking_liberator_data_upload_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${var.identifier_prefix}_parking_liberator_data_upload"
  s3_bucket        = aws_s3_bucket.parking_lambda_artefact_storage.id
  s3_key           = aws_s3_bucket_object.parking_liberator_data_upload_lambda.key
  source_code_hash = data.archive_file.parking_liberator_data_upload_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      SFTP_HOST     = local.liberator_data_sftp_server_host.value
      SFTP_USERNAME = local.liberator_data_sftp_server_username.value
      SFTP_PASSWORD = local.liberator_data_sftp_server_password.value
      S3_BUCKET     = var.landing_zone_bucket_id
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_day_at_six" {
  name                = "every-day-at-six"
  description         = "Runs every day at 6am"
  schedule_expression = "cron(0 06 * * ? *)"
}

resource "aws_cloudwatch_event_target" "run_liberator_uploader_every_day" {
  rule      = aws_cloudwatch_event_rule.every_day_at_six.name
  target_id = "parking_liberator_data_upload_lambda"
  arn       = aws_lambda_function.parking_liberator_data_upload_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_parking_liberator_data_upload_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.parking_liberator_data_upload_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_at_six.arn
}
