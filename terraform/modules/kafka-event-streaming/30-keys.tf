locals {
  default_arn = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
  ]
}

resource "aws_kms_key" "kafka" {
  tags        = var.tags
  description = "${var.short_identifier_prefix} - Kafka Streaming"

  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.kafka_client_access.json
}

data "aws_iam_policy_document" "kafka_client_access" {
  statement {
    actions = ["kms:*"]

    principals {
      identifiers = concat(var.cross_account_lambda_roles, local.default_arn)
      type        = "AWS"
    }

    resources = ["*"]
  }
}

resource "aws_kms_alias" "key_alias" {
  name          = lower("alias/${var.short_identifier_prefix}kafka-${aws_msk_cluster.kafka_cluster.cluster_name}")
  target_key_id = aws_kms_key.kafka.key_id
}