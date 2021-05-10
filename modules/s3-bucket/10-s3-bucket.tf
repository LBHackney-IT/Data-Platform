data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "key_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      aws_kms_key.key.arn
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
  }

  statement {
    sid = "CrossAccountShare"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.key.arn
    ]
    principals {
      type = "AWS"
      identifiers = var.role_arns_to_share_access_with
    }
  }
}

resource "aws_kms_key" "key" {
  tags = var.tags

  description             = "${var.project} ${var.environment} - ${var.bucket_name} Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.key_policy.json
}


resource "aws_kms_alias" "key_alias" {
  name = lower("alias/${var.identifier_prefix}-s3-${var.bucket_identifier}")
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_s3_bucket" "bucket" {
  tags = var.tags

  bucket = lower("${var.identifier_prefix}-${var.bucket_identifier}")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket.bucket]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
