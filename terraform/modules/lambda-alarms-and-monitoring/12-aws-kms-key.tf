resource "aws_kms_key" "lambda_failure_notifications_kms_key" {
  tags                    = var.tags
  description             = "${var.project} - ${var.environment} - lambda-failure-notification-${var.identifier_prefix} KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.lambda_failure_notifications_kms_key_policy.json
}

resource "aws_kms_alias" "lambda_failure_notifications_kms_key_alias" {
  name          = lower("alias/${var.lambda_name}-lambda-failure-notifications")
  target_key_id = aws_kms_key.lambda_failure_notifications_kms_key.key_id
}

data "aws_iam_policy_document" "lambda_failure_notifications_kms_key_policy" {

  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.data_platform.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    principals {
      identifiers = ["cloudwatch.amazonaws.com"]
      type        = "Service"
    }

    resources = ["*"]
  }
}
