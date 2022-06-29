resource "aws_ecr_repository" "worker" {
  tags = var.tags
  name = var.operation_name
  image_scanning_configuration {
    scan_on_push = true
  }
}
