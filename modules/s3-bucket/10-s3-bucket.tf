resource "aws_kms_key" "key" {
  tags = var.tags

  description             = "${var.project} ${var.environment} - ${var.bucket_name} Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
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

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "bucket_policy_document" {

  statement {
    sid    = "ListBucket"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = concat([
      for account_id, v in var.account_configuration :
      "arn:aws:iam::${account_id}:root"
      ], [
      for account_id, v in var.account_configuration :
      "arn:aws:iam::${account_id}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"
      ])
    }
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bucket.arn]
  }

  dynamic "statement" {
    for_each = var.account_configuration
    iterator = account
    content {
      sid    = "WriteAccess${account.key}"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${account.key}:root",
          "arn:aws:iam::${account.key}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
        ]
      }
      condition {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
      actions   = ["s3:PutObject", "s3:PutObjectAcl"]
      resources = ["${aws_s3_bucket.bucket.arn}/${account.value["read_write"]}/*"]
    }
  }
  dynamic "statement" {
    for_each = var.account_configuration
    iterator = account
    content {
      sid    = "ReadAccess${account.key}"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${account.key}:root",
          "arn:aws:iam::${account.key}:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
        ]
      }
      actions = ["s3:GetObject"]
      resources = concat(
        [for readable_folder in account.value["read"]: "${aws_s3_bucket.bucket.arn}/${readable_folder}/*"],
        ["${aws_s3_bucket.bucket.arn}/${account.value["read_write"]}/*"]
      )
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket_policy_document.json
}
