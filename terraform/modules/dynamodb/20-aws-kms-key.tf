resource "aws_kms_key" "dynamodb" {
  description             = "${var.identifier_prefix} - ${var.name} dynamodb table KMS key "
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.dynamodb_key_policy.json
  tags                    = var.tags
}

resource "aws_kms_alias" "dynamodb_kms_alias" {
  name          = "alias/${var.identifier_prefix}${var.name}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

data "aws_iam_policy_document" "dynamodb_key_policy" {

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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
