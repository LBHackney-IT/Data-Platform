module "sftp_to_s3_ingestion" {
  count  = local.is_live_environment ? 1 : 0
  source = "../modules/api-ingestion-lambda"
  tags   = module.tags.values

  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "sftp-to-s3"
  lambda_handler                 = "index.handler"
  runtime_language               = "nodejs14.x"
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  s3_target_bucket_arn           = module.landing_zone.bucket_arn
  s3_target_bucket_name          = local.s3_target_bucket_name
  api_credentials_secret_name    = local.secret_name
  glue_job_to_trigger            = local.glue_job_name
  s3_target_bucket_kms_key_arn   = module.landing_zone.kms_key_arn
  ephemeral_storage              = 6144
  lambda_environment_variables = {
    "SFTP_HOST"         = local.sftp_server_host.value
    "SFTP_USERNAME"     = local.sftp_server_username.value
    "SFTP_PASSWORD"     = local.sftp_server_password.value
    "S3_BUCKET"         = var.s3_target_bucket_id
    "OBJECT_KEY_PREFIX" = "${var.department_identifier}"
  }
}


# resource "aws_lambda_function" "sftp_to_s3_lambda" {
#   tags = var.tags

#   role             = aws_iam_role.sftp_to_s3_lambda.arn
#   handler          = "index.handler"
#   runtime          = "nodejs14.x"
#   function_name    = "${var.identifier_prefix}-sftp-to-s3"
#   s3_bucket        = var.lambda_artefact_storage_bucket
#   s3_key           = aws_s3_bucket_object.sftp_to_s3_lambda.key
#   source_code_hash = data.archive_file.sftp_to_s3_lambda.output_base64sha256
#   timeout          = local.lambda_timeout

#   environment {
#     variables = {
#       SFTP_HOST         = local.liberator_data_sftp_server_host.value
#       SFTP_USERNAME     = local.liberator_data_sftp_server_username.value
#       SFTP_PASSWORD     = local.liberator_data_sftp_server_password.value
#       S3_BUCKET         = var.s3_bucket_id
#       OBJECT_KEY_PREFIX = "${var.department_identifier}"
#     }
#   }
# }

# resource "aws_cloudwatch_event_rule" "every_day_at_six" {
#   name                = "${var.identifier_prefix}-every-day-at-six"
#   description         = "Runs every day at 6am"
#   schedule_expression = "cron(0 06 * * ? *)"
#   is_enabled          = var.run_daily
# }

# resource "aws_cloudwatch_event_target" "run_liberator_uploader_every_day" {
#   rule      = aws_cloudwatch_event_rule.every_day_at_six.name
#   target_id = aws_lambda_function.sftp_to_s3_lambda.function_name
#   arn       = aws_lambda_function.sftp_to_s3_lambda.arn
# }

# resource "aws_lambda_permission" "allow_cloudwatch_to_call_sftp_to_s3_lambda" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.sftp_to_s3_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.every_day_at_six.arn
# }