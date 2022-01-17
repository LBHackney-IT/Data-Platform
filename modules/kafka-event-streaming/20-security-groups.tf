resource "aws_security_group" "kafka" {
  name   = "${var.identifier_prefix}-kafka"
  tags   = var.tags
  vpc_id = var.vpc_id
}