resource "aws_cloudwatch_log_group" "connector_log_group" {
  tags = var.tags
  name = "${var.short_identifier_prefix}kafka-connector"
}

resource "aws_cloudwatch_log_group" "broker_log_group" {
  tags = var.tags
  name = "${var.short_identifier_prefix}event-streaming-broker-logs"
}