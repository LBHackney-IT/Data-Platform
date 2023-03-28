locals {
  lambda_name_underscore = replace(lower(var.function_name), "/[^a-zA-Z0-9]+/", "_")
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../../lambdas/${local.lambda_name_underscore}"
  output_path = "../../lambdas/${local.lambda_name_underscore}.zip"
}

resource "aws_s3_bucket_object" "lambda" {
  bucket = var.lambda_artefact_storage_bucket
  key    = "${local.lambda_name_underscore}.zip"
  source = data.archive_file.lambda.output_path
  etag   = filemd5(data.archive_file.lambda.output_path)
  acl    = "private"
}

resource "aws_lambda_function" "lambda" {
  function_name     = lower("${var.identifier_prefix}${var.function_name}")
  role              = aws_iam_role.lambda.arn
  handler           = "main.lambda_handler"
  runtime           = "python3.8"
  source_code_hash  = filebase64sha256(data.archive_file.lambda.output_path)
  s3_bucket         = var.lambda_artefact_storage_bucket
  s3_key            = "${local.lambda_name_underscore}.zip"
  s3_object_version = aws_s3_bucket_object.lambda.version_id
  environment {
    variables = var.lambda_environment_variables
  }
  tags = var.tags
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowExecutionFromCloudWatch-${var.function_name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
