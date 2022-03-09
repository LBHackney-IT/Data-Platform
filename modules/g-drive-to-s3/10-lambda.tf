data "aws_iam_policy_document" "g_drive_to_s3_copier_lambda_assume_role" {
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

resource "aws_iam_role" "g_drive_to_s3_copier_lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}-from-g-drive-${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.g_drive_to_s3_copier_lambda_assume_role.json
}

data "aws_iam_policy_document" "g_drive_to_s3_copier_lambda" {
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

  dynamic "statement" {
    for_each = var.workflow_arns == "" ? [] : [1]

    content {
      actions = [
        "glue:StartWorkflowRun",
      ]
      effect    = "Allow"
      resources = var.workflow_arns
    }
  }
}

resource "aws_iam_policy" "g_drive_to_s3_copier_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-from-g-drive-to-s3-copier-lambda")
  policy = data.aws_iam_policy_document.g_drive_to_s3_copier_lambda.json
}

resource "aws_iam_role_policy_attachment" "g_drive_to_s3_copier_lambda" {

  role       = aws_iam_role.g_drive_to_s3_copier_lambda.name
  policy_arn = aws_iam_policy.g_drive_to_s3_copier_lambda.arn
}

data "archive_file" "g_drive_to_s3_copier_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/g_drive_to_s3"
  output_path = "../lambdas/g_drive_to_s3.zip"
}

resource "aws_s3_bucket_object" "g_drive_to_s3_copier_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "g_drive_to_s3.zip"
  source      = data.archive_file.g_drive_to_s3_copier_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.g_drive_to_s3_copier_lambda.output_md5
  depends_on = [
    data.archive_file.g_drive_to_s3_copier_lambda
  ]
}

resource "aws_lambda_function" "g_drive_to_s3_copier_lambda" {
  tags = var.tags

  role             = aws_iam_role.g_drive_to_s3_copier_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = lower("${var.identifier_prefix}from-g-drive-${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.g_drive_to_s3_copier_lambda.key
  source_code_hash = data.archive_file.g_drive_to_s3_copier_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      FILE_ID        = var.file_id
      BUCKET_ID      = var.zone_bucket_id
      FILE_NAME      = "${var.service_area}/${var.file_name}"
      WORKFLOW_NAMES = join("/", var.workflow_names)
    }
  }

  depends_on = [
    aws_s3_bucket_object.g_drive_to_s3_copier_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "g_drive_to_s3_copier_lambda" {

  function_name          = aws_lambda_function.g_drive_to_s3_copier_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.g_drive_to_s3_copier_lambda
  ]
}

resource "aws_cloudwatch_event_rule" "every_day_at_6" {
  name                = "g-drive-to-s3-copier-every-day-at-6"
  description         = "Fires every dat at "
  schedule_expression = "cron(0 6 * * ? *)"
  is_enabled          = false
}

resource "aws_cloudwatch_event_target" "run_lambda_every_day_at_6" {
  rule      = aws_cloudwatch_event_rule.every_day_at_6.name
  target_id = "g_drive_to_s3_copier_lambda"
  arn       = aws_lambda_function.g_drive_to_s3_copier_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_g_drive_to_s3_copier" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.g_drive_to_s3_copier_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_at_6.arn
}
