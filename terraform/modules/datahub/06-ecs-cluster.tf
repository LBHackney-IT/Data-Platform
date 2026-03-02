resource "aws_ecs_cluster" "datahub" {
  tags = var.tags
  name = "${var.short_identifier_prefix}datahub"
}