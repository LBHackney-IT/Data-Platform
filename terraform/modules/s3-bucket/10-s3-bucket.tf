data "aws_iam_policy_document" "key_policy" {
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
      identifiers = local.current_arn
    }
  }

  statement {
    sid    = "CrossAccountShare"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = local.role_arns_to_share_access_with
    }
  }

  dynamic "statement" {
    for_each = var.bucket_key_policy_statements

    content {
      sid       = lookup(statement.value, "sid", "")
      effect    = lookup(statement.value, "effect", "")
      actions   = lookup(statement.value, "actions", [])
      resources = ["*"]

      principals {
        type        = lookup(statement.value.principals, "type", "")
        identifiers = lookup(statement.value.principals, "identifiers", [])
      }
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
  name          = lower("alias/${var.identifier_prefix}-s3-${var.bucket_identifier}")
  target_key_id = aws_kms_key.key.key_id
}

data "aws_iam_policy_document" "bucket_policy_document" {
  statement {
    sid    = "CrossAccountShare"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = local.role_arns_to_share_access_with
    }
  }

  dynamic "statement" {
    for_each = var.bucket_policy_statements

    content {
      sid       = lookup(statement.value, "sid", "")
      effect    = lookup(statement.value, "effect", "")
      actions   = lookup(statement.value, "actions", [])
      resources = lookup(statement.value, "resources", [])

      principals {
        type        = lookup(statement.value.principals, "type", "")
        identifiers = lookup(statement.value.principals, "identifiers", [])
      }
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  tags = var.tags

  bucket = lower("${var.identifier_prefix}-${var.bucket_identifier}")

  force_destroy = (var.environment == "dev")

}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count  = var.expire_objects_days != null ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "expire-older-objects"
    status = "Enabled"

    expiration {
      days = var.expire_objects_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.expire_noncurrent_objects_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_multipart_days
    }

  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket     = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket.bucket]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket     = aws_s3_bucket.bucket.id
  policy     = data.aws_iam_policy_document.bucket_policy_document.json
  depends_on = [aws_s3_bucket_public_access_block.block_public_access]
}
