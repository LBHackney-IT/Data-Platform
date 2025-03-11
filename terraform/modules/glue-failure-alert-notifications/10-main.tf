locals {
  lambda_name_underscore = replace(lower(var.lambda_name), "/[^a-zA-Z0-9]+/", "_")
}


data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = lower("${var.identifier_prefix}${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    effect    = "Allow"
    resources = [var.secrets_manager_kms_key.arn]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*"]
  }

  statement {
    actions = [
      "glue:GetJob",
      "glue:GetJobRun",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = lower("${var.identifier_prefix}${var.lambda_name}")
  policy = data.aws_iam_policy_document.lambda.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "../../lambdas/${local.lambda_name_underscore}"
  output_path = "../../lambdas/${local.lambda_name_underscore}.zip"
}

resource "aws_s3_object" "lambda" {
  bucket = var.lambda_artefact_storage_bucket
  key    = "${local.lambda_name_underscore}.zip"
  source = data.archive_file.lambda.output_path
  acl    = "private"
  metadata = {
    last_updated = data.archive_file.lambda.output_base64sha256
  }
}

resource "aws_lambda_function" "lambda" {
  function_name     = lower("${var.identifier_prefix}${var.lambda_name}")
  role              = aws_iam_role.lambda.arn
  handler           = "main.lambda_handler"
  runtime           = "python3.9"
  source_code_hash  = filebase64sha256(data.archive_file.lambda.output_path)
  s3_bucket         = var.lambda_artefact_storage_bucket
  s3_key            = "${local.lambda_name_underscore}.zip"
  s3_object_version = aws_s3_object.lambda.version_id
  timeout           = var.timeout
  environment {
    variables = var.lambda_environment_variables
  }
  tags = var.tags
}

resource "aws_lambda_permission" "lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda.arn
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name          = lower("${var.identifier_prefix}${var.lambda_name}")
  description   = "Event rule for triggering lambda ${var.lambda_name}"
  event_pattern = var.cloudwatch_event_pattern
  is_enabled    = true

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.lambda.name
  target_id = "Invoke${var.lambda_name}Lambda"
  arn       = aws_lambda_function.lambda.arn
}
