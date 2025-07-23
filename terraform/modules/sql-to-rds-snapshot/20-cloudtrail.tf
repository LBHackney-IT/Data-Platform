resource "aws_cloudtrail" "events" {
  count = var.is_production_environment ? 1 : 0

  name                          = var.identifier_prefix
  s3_bucket_name                = var.cloudtrail_bucket_id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloud_trail_events.arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_events_role.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"

      # Make sure to append a trailing '/' to your ARN if you want
      # to monitor all objects in a bucket.
      values = ["arn:aws:s3:::${var.watched_bucket_name}/"]
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.cloud_trail_events
  ]
}

resource "aws_cloudwatch_log_group" "cloud_trail_events" {
  name = "${var.identifier_prefix}-cloudtrail-events"
}

resource "aws_iam_role" "cloudtrail_cloudwatch_events_role" {
  name               = "${var.identifier_prefix}-cloudtrail-events"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_role_policy" "policy" {
  name   = "${var.identifier_prefix}-cloudtrail-events"
  role   = aws_iam_role.cloudtrail_cloudwatch_events_role.id
  policy = data.aws_iam_policy_document.policy.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream"]
    resources = ["${aws_cloudwatch_log_group.cloud_trail_events.arn}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cloud_trail_events.arn}:*"]
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "sql_to_rds_snapshot_cloudtrail_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [var.cloudtrail_bucket_arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${var.cloudtrail_bucket_arn}/prefix/AWSLogs/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "AllowSSLRequestsOnly"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      var.cloudtrail_bucket_arn,
      "${var.cloudtrail_bucket_arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

# Apply the bucket policy to the external bucket (only in production)
resource "aws_s3_bucket_policy" "sql_to_rds_snapshot_cloudtrail_bucket_policy" {
  count  = var.is_production_environment ? 1 : 0
  bucket = var.cloudtrail_bucket_id
  policy = data.aws_iam_policy_document.sql_to_rds_snapshot_cloudtrail_bucket_policy.json
}
