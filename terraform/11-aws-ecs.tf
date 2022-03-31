resource "aws_ecs_cluster" "workers" {
  tags = module.tags.values
  name = "${local.identifier_prefix}-workers"
}