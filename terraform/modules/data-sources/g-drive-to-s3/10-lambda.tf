data "aws_iam_role" "g_drive_to_s3_copier_lambda" {
  name = lower("${var.identifier_prefix}from-g-drive-${var.lambda_name}")
}

data "aws_s3_object" "g_drive_to_s3_copier_lambda" {
  bucket = var.lambda_artefact_storage_bucket
  key    = "g_drive_to_s3.zip"
}

data "aws_lambda_function" "g_drive_to_s3_copier_lambda" {
  function_name = lower("${var.identifier_prefix}g-drive-${var.lambda_name}")
}

data "aws_lambda_function_event_invoke_config" "g_drive_to_s3_copier_lambda" {
  function_name = data.aws_lambda_function.g_drive_to_s3_copier_lambda.function_name
}

data "aws_cloudwatch_event_rule" "every_day_at_6" {
  name_prefix = "g-drive-to-s3-copier-every-day-at-6-"
}
