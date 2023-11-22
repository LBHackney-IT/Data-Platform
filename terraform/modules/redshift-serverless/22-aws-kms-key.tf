resource "aws_kms_key" "key" {
    tags = var.tags

    description = "${var.identifier_prefix}-redshift-serverless-${var.namespace_name}-namespace"
    deletion_window_in_days = 10
    enable_key_rotation = true

    policy = data.aws_iam_policy_document.key_policy.json
}

data "aws_iam_policy_document" "key_policy" {
    statement {
      effect = "Allow"
      actions = [
        "kms:*"
      ]
      
      resources = ["*"]

        principals {
          type = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }

    }
}

resource "aws_kms_alias" "name" {
  name = lower("alias/${var.identifier_prefix}-redshift-serverless-${var.namespace_name}-namespace")
  target_key_id = aws_kms_key.key.id
}

