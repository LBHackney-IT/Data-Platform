resource "aws_cloudtrail" "foobar" {
  name                          = var.identifier_prefix
  s3_bucket_name                = aws_s3_bucket.foo.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.example.arn}:*" # CloudTrail requires the Log Stream wildcard
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


resource "aws_cloudwatch_log_group" "example" {
  name = "${var.identifier_prefix}-cloudtrail"
}
