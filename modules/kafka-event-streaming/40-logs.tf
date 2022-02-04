resource "aws_cloudwatch_log_group" "connector_log_group" {
  name = "${var.identifier_prefix}kafka-connector"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "broker_log_group" {
  tags = var.tags
  name = "${var.identifier_prefix}event-streaming-broker-logs"
}