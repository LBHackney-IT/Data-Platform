resource "aws_s3_bucket" "qlik_alb_logs" {
  count  = var.is_live_environment ? 1 : 0
  tags   = var.tags
  bucket = "${var.identifier_prefix}-qlik-alb-logs"
}

resource "aws_s3_bucket_acl" "qlik_alb_logs" {
  count  = var.is_live_environment ? 1 : 0
  bucket = aws_s3_bucket.qlik_alb_logs[0].id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "qlik_alb_logs_public_access" {
  count  = var.is_live_environment ? 1 : 0
  bucket = aws_s3_bucket.qlik_alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "qlik_alb_logs_s3_encryption" {
  count  = var.is_live_environment ? 1 : 0
  bucket = aws_s3_bucket.qlik_alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "qlik_alb_logs_versioning" {
  count  = var.is_live_environment ? 1 : 0
  bucket = aws_s3_bucket.qlik_alb_logs[0].id

  versioning_configuration {
    status = "Disabled"
  }
}

data "aws_iam_policy_document" "write_access_for_aws_loggers" {
  count  = var.is_live_environment ? 1 : 0
  
  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    resources = [aws_s3_bucket.qlik_alb_logs[0].arn]
    actions   = ["s3:GetBucketAcl"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    resources = [aws_s3_bucket.qlik_alb_logs[0].arn,
    "${aws_s3_bucket.qlik_alb_logs[0].arn}/*"]
    actions = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowELBAccountWriteAccess"
    effect = "Allow"
    resources = [aws_s3_bucket.qlik_alb_logs[0].arn,
    "${aws_s3_bucket.qlik_alb_logs[0].arn}/*"]
    actions = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::652711504416:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "write_access_for_aws_loggers" {
  count  = var.is_live_environment ? 1 : 0

  bucket = aws_s3_bucket.qlik_alb_logs[0].id
  policy = data.aws_iam_policy_document.write_access_for_aws_loggers[0].json
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_lifecycle" {
  count  = var.is_live_environment ? 1 : 0
  bucket = aws_s3_bucket.qlik_alb_logs[0].id

  rule {
    id = "rule-1"

    filter {}

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}
