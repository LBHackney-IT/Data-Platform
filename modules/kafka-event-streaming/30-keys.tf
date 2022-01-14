#resource "aws_kms_key" "kms" {
#  tags        = var.tags
#  description = "${var.identifier_prefix}MMH Kafka streaming"
#}
#
#
#resource "aws_kms_alias" "key_alias" {
#  name          = lower("alias/${var.identifier_prefix}kafka-${aws_msk_cluster.mmh_streaming.cluster_name}")
#  target_key_id = aws_kms_key.kms.key_id
#}