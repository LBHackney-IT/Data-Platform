data "aws_iam_policy_document" "tascomi_api_ingestor_lambda_assume_role" {
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

resource "aws_iam_role" "tascomi_api_ingestor_lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}-api-ingestion-lambda-tascomi")
  assume_role_policy = data.aws_iam_policy_document.tascomi_api_ingestor_lambda_assume_role.json
}

data "aws_iam_policy_document" "tascomi_api_ingestor_lambda" {
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
    actions = [
      "kms:*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      var.zone_kms_key_arn,
      var.zone_bucket_arn,
      "${var.zone_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "glue:StartWorkflowRun",
    ]
    effect    = "Allow"
    resources = [aws_glue_workflow.workflow.arn]
  }
}

resource "aws_iam_policy" "tascomi_api_ingestor_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-tascomi-api-ingestor-lambda")
  policy = data.aws_iam_policy_document.tascomi_api_ingestor_lambda.json
}

resource "aws_iam_role_policy_attachment" "tascomi_api_ingestor_lambda" {

  role       = aws_iam_role.tascomi_api_ingestor_lambda.name
  policy_arn = aws_iam_policy.tascomi_api_ingestor_lambda.arn
}

data "archive_file" "tascomi_api_ingestor_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/tascomi_api_ingestor"
  output_path = "../lambdas/tascomi_api_ingestor.zip"
}

resource "aws_s3_bucket_object" "tascomi_api_ingestor_lambda" {
  tags = var.tags

  bucket = var.lambda_artefact_storage_bucket
  key    = "tascomi_api_ingestor.zip"
  source = data.archive_file.tascomi_api_ingestor_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.tascomi_api_ingestor_lambda.output_md5
  depends_on = [
    data.archive_file.tascomi_api_ingestor_lambda
  ]
}

resource "aws_lambda_function" "tascomi_api_ingestor_lambda" {
  tags = var.tags

  role             = aws_iam_role.tascomi_api_ingestor_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = lower("${var.identifier_prefix}-api-ingestor-tascomi-${var.resource_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.tascomi_api_ingestor_lambda.key
  source_code_hash = data.archive_file.tascomi_api_ingestor_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      S3_TARGET      = local.bucket_source
      BUCKET_ID      = var.zone_bucket_id
      RESOURCE       = var.resource_name
      WORKFLOW_NAMES = aws_glue_workflow.workflow.id
      PUBLIC_KEY     = var.tascomi_public_key
      PRIVATE_KEY    = var.tascomi_private_key
    }
  }

  depends_on = [
    aws_s3_bucket_object.tascomi_api_ingestor_lambda
  ]
}

resource "aws_lambda_function_event_invoke_config" "tascomi_api_ingestor_lambda" {

  function_name          = aws_lambda_function.tascomi_api_ingestor_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.tascomi_api_ingestor_lambda
  ]
}

resource "aws_cloudwatch_event_rule" "every_day_at_6" {
  name                = "tascomi-api-ingestor-every-day-at-6"
  description         = "Fires every dat at "
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "run_lambda_every_day_at_6" {
  rule      = aws_cloudwatch_event_rule.every_day_at_6.name
  target_id = "tascomi_api_ingestor_lambda"
  arn       = aws_lambda_function.tascomi_api_ingestor_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_tascomi_api_ingestor" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tascomi_api_ingestor_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_at_6.arn
}
