resource "aws_ecr_repository" "datahub" {
  tags = var.tags
  name = "${var.short_identifier_prefix}datahub"
}