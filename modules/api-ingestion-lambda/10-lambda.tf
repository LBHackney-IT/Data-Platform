data "aws_iam_policy_document" "api_ingestion_lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "api_ingestion_lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}api-ingestion-${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.api_ingestion_lambda_assume_role.json
}

data "aws_iam_policy_document" "api_ingestion_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key.arn
    ]
  }

  statement {
    actions = [
      "kms:*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      var.s3_target_bucket_kms_key_arn,
      var.s3_target_bucket_arn,
      "${var.s3_target_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_policy" "api_ingestion_lambda" {
  tags = var.tags

  name_prefix = lower("${var.identifier_prefix}api-ingestion-lambda-${var.lambda_name}")
  policy      = data.aws_iam_policy_document.api_ingestion_lambda.json
}

resource "aws_iam_role_policy_attachment" "api_ingestion_lambda" {

  role       = aws_iam_role.api_ingestion_lambda.name
  policy_arn = aws_iam_policy.api_ingestion_lambda.arn
}

data "archive_file" "api_ingestion_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/api_ingestion"
  output_path = "../lambdas/api_ingestion.zip"
}

resource "aws_s3_bucket_object" "api_ingestion_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "api_ingestion.zip"
  source      = data.archive_file.api_ingestion_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.api_ingestion_lambda.output_md5
  depends_on = [
    data.archive_file.api_ingestion_lambda
  ]
}

resource "aws_lambda_function" "api_ingestion_lambda" {
  tags = var.tags

  role             = aws_iam_role.api_ingestion_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = lower("${var.identifier_prefix}api-ingestion-${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.api_ingestion_lambda.key
  source_code_hash = data.archive_file.api_ingestion_lambda.output_base64sha256
  timeout          = local.lambda_timeout
  memory_size      = local.lambda_memory_size

  environment {
    variables = {
      API_CREDENTIALS  = data.aws_secretsmanager_secret_version.api_credentials_for_lambda.secret_string
      TARGET_S3_BUCKET = var.s3_target_bucket_arn
      OUTPUT_FOLDER    = var.output_folder_name
      REPORT_ID        = var.report_id
    }
  }

  depends_on = [
    aws_s3_bucket_object.api_ingestion_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "api_ingestion_lambda" {

  function_name          = aws_lambda_function.api_ingestion_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.api_ingestion_lambda
  ]
}

resource "aws_cloudwatch_event_rule" "run_api_ingestion_lambda" {
  name_prefix         = "${var.lambda_name}-api-ingestion-lambda-"
  description         = "Fires every dat at "
  schedule_expression = var.lambda_execution_cron_schedule
}

resource "aws_cloudwatch_event_target" "run_lambda_every_day_at_6" {
  rule      = aws_cloudwatch_event_rule.run_api_ingestion_lambda.name
  target_id = "${var.lambda_name}-api-ingestion-"
  arn       = aws_lambda_function.api_ingestion_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_api_ingestion_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_ingestion_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_api_ingestion_lambda.arn
}
