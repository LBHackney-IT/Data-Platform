resource "aws_iam_role" "lambda" {
  name               = "${var.identifier_prefix}lambda-${local.lambda_name_underscore}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
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
}

resource "aws_iam_policy" "lambda" {
  name   = local.lambda_name_underscore
  policy = data.aws_iam_policy_document.lambda.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

