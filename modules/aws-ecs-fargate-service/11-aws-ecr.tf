resource "aws_ecr_repository" "worker" {
  tags = var.tags
  name = var.operation_name
}
