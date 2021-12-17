resource "aws_security_group" "sg" {
  name   = "${var.identifier_prefix}mmh-kafka-streaming"
  tags   = var.tags
  vpc_id = var.vpc_id
}