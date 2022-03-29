resource "aws_cloudwatch_log_group" "datahub" {
  name = "${var.operation_name}-datahub"
  tags = var.tags
}