resource "aws_cloudwatch_log_group" "datahub" {
  name = "${var.short_identifier_prefix}datahub"
  tags = var.tags
}