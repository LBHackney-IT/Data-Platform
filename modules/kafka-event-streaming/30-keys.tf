resource "aws_kms_key" "kafka" {
  tags        = var.tags
  description = "${var.identifier_prefix} - Kafka Streaming"

  deletion_window_in_days = 10
  enable_key_rotation     = true

  // policy = ??
}

resource "aws_kms_alias" "key_alias" {
  name          = lower("alias/${var.identifier_prefix}kafka-${aws_msk_cluster.kafka_cluster.cluster_name}")
  target_key_id = aws_kms_key.kafka.key_id
}