resource "aws_cloudwatch_log_group" "mmh_log_group" {
  name = "msk_broker_logs"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "mmh-msk-broker-logs-bucket"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose_msk_role"

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "firehose.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
  ]
}
EOF
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