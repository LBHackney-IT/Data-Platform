data "aws_iam_policy_document" "sftp_to_s3_lambda_assume_role" {
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

resource "aws_iam_role" "sftp_to_s3_lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.sftp_to_s3_lambda_assume_role.json
}

data "aws_iam_policy_document" "sftp_to_s3_lambda" {
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
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.identifier_prefix}/${var.department_identifier}/sheets-credential*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
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
      var.destination_bucket_kms_key_arn,
      var.destination_bucket_arn,
      "${var.destination_bucket_arn}/*",
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

resource "aws_iam_policy" "sftp_to_s3_lambda" {
  tags = var.tags

  name_prefix = lower("${var.identifier_prefix}-sftp-to-s3-lambda")
  policy      = data.aws_iam_policy_document.sftp_to_s3_lambda.json
}

resource "aws_iam_role_policy_attachment" "sftp_to_s3_lambda" {
  role       = aws_iam_role.sftp_to_s3_lambda.name
  policy_arn = aws_iam_policy.sftp_to_s3_lambda.arn
}

data "archive_file" "sftp_to_s3_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/sftp_to_s3"
  output_path = "../lambdas/sftp_to_s3.zip"
}

resource "aws_s3_bucket_object" "sftp_to_s3_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "sftp_to_s3.zip"
  source      = data.archive_file.sftp_to_s3_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.sftp_to_s3_lambda.output_md5
  depends_on = [
    data.archive_file.sftp_to_s3_lambda
  ]
}

resource "aws_lambda_function" "sftp_to_s3_lambda" {
  tags = var.tags

  role             = aws_iam_role.sftp_to_s3_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = lower("${var.identifier_prefix}${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.sftp_to_s3_lambda.key
  source_code_hash = data.archive_file.sftp_to_s3_lambda.output_base64sha256
  timeout          = local.lambda_timeout
  memory_size      = local.lambda_memory_size

  environment {
    variables = {
      FILE_ID                                       = var.file_id
      BUCKET_ID                                     = var.zone_bucket_id
      FILE_NAME                                     = "${var.service_area}/${var.output_folder_name}/${var.file_name}"
      WORKFLOW_NAMES                                = join("/", var.workflow_names)
      GOOGLE_SERVICE_ACCOUNT_CREDENTIALS_SECRET_ARN = var.google_service_account_credentials_secret
    }
  }

  depends_on = [
    aws_s3_bucket_object.sftp_to_s3_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "sftp_to_s3_lambda" {

  function_name          = aws_lambda_function.sftp_to_s3_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.sftp_to_s3_lambda
  ]
}

resource "aws_cloudwatch_event_rule" "every_day_at_6" {
  name_prefix         = "sftp-to-s3-every-day-at-6-"
  description         = "Fires every dat at "
  schedule_expression = "cron(0 6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "run_lambda_every_day_at_6" {
  rule      = aws_cloudwatch_event_rule.every_day_at_6.name
  target_id = "sftp_to_s3_lambda"
  arn       = aws_lambda_function.sftp_to_s3_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_sftp_to_s3" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sftp_to_s3_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day_at_6.arn
}
