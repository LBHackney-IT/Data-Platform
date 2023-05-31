resource "aws_iam_role" "lambda_role" {
  name = "${var.identifier_prefix}${var.lambda_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "lambda_role" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.enable_kms_key_access ? [1] : []
    content {
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey",
      ]
      effect    = "Allow"
      resources = [var.secrets_manager_kms_key.arn]
    }
  }
  dynamic "statement" {
    for_each = var.enable_secrets_manager_access ? [1] : []

    content {
      actions = [
        "secretsmanager:GetSecretValue",
      ]
      effect    = "Allow"
      resources = ["arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}*"]
    }
  }
}

resource "aws_iam_policy" "lambda_role" {
  name   = lower("${var.identifier_prefix}${var.lambda_name}")
  policy = data.aws_iam_policy_document.lambda_role.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_role.arn
}
