resource "aws_cloudwatch_log_group" "connector_log_group" {
  name = "${var.identifier_prefix}kafka-connector"

  tags = var.tags
}

#resource "aws_cloudwatch_log_group" "mmh_log_group" {
#  tags = var.tags
#  name = "${var.identifier_prefix}msk_broker_logs"
#}
#
#resource "aws_s3_bucket" "bucket" {
#  tags   = var.tags
#  bucket = "${var.identifier_prefix}mmh-msk-broker-logs-bucket"
#  acl    = "private"
#}
#
#data "aws_iam_policy_document" "firehose_assume_role" {
#  statement {
#    actions = ["sts:AssumeRole"]
#
#    principals {
#      identifiers = ["firehose.amazonaws.com"]
#      type        = "Service"
#    }
#  }
#}
#
#resource "aws_iam_role" "firehose_role" {
#  tags = var.tags
#  name = "${var.identifier_prefix}firehose_msk_role"
#
#  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
#}
#
#resource "aws_kinesis_firehose_delivery_stream" "mmh_delivery_logs_stream" {
#  name        = "${var.identifier_prefix}terraform-kinesis-firehose-msk-broker-logs-stream"
#  destination = "s3"
#  tags        = merge(var.tags, { LogDeliveryEnabled = "placeholder" })
#
#  s3_configuration {
#    role_arn   = aws_iam_role.firehose_role.arn
#    bucket_arn = aws_s3_bucket.bucket.arn
#  }
#
#  lifecycle {
#    ignore_changes = [
#      tags["LogDeliveryEnabled"],
#    ]
#  }
#}