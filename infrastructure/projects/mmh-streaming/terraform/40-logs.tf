resource "aws_cloudwatch_log_group" "mmh_log_group" {
  name = "msk_broker_logs"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "mmh-msk-broker-logs-bucket"
  acl    = "private"
}

data "aws_iam_policy_document" "firehose_assume_role" {
  provider = aws.core

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["firehose.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_msk_role"

  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_kinesis_firehose_delivery_stream" "mmh_delivery_logs_stream" {
  name        = "terraform-kinesis-firehose-msk-broker-logs-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
  }

  tags = {
    LogDeliveryEnabled = "placeholder"
  }

  lifecycle {
    ignore_changes = [
      tags["LogDeliveryEnabled"],
    ]
  }
}