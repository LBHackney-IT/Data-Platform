resource "aws_cloudtrail" "events" {
  name                          = var.identifier_prefix
  s3_bucket_name                = aws_s3_bucket.foo.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloud_trail_events.arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_events_role.arn

  depends_on = [
    aws_cloudwatch_log_group.cloud_trail_events
  ]
}

resource "aws_cloudwatch_log_group" "cloud_trail_events" {
  name = "${var.identifier_prefix}-cloudtrail-events"
}

resource "aws_iam_role" "cloudtrail_cloudwatch_events_role" {
  name_prefix        = "cloudtrail_events_role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy.json}"
}

resource "aws_iam_role_policy" "policy" {
  name_prefix = "cloudtrail_cloudwatch_events_policy"
  role        = "${aws_iam_role.cloudtrail_cloudwatch_events_role.id}"
  policy      = "${data.aws_iam_policy_document.policy.json}"
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

resource "aws_s3_bucket" "foo" {
  bucket        = "${var.identifier_prefix}-cloudtrail"
  force_destroy = true

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.identifier_prefix}-cloudtrail"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.identifier_prefix}-cloudtrail/prefix/AWSLogs/${var.aws_caller_identity}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}
