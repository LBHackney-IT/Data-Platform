resource "aws_ecs_cluster" "datahub" {
  tags = var.tags
  name = "${var.identifier_prefix}-datahub"
}