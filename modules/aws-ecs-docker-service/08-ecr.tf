resource "aws_ecr_repository" "ecr" {
  tags = var.tags
  name = "${var.operation_name}${var.container_properties.container_name}"
}