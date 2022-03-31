resource "aws_cloudwatch_log_group" "datahub" {
  name = "${var.operation_name}${var.container_properties.container_name}"
  tags = var.tags
}