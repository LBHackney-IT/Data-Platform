resource "aws_ecr_repository" "ecr" {
  tags = var.tags
  name = "${var.short_identifier_prefix}${var.container_properties.container_name}"
  image_scanning_configuration {
    scan_on_push = true
  }
}