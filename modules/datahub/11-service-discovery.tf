resource "aws_service_discovery_private_dns_namespace" "datahub" {
  name        = "${var.short_identifier_prefix}datahub.net"
  description = "Domain for ECS service"
  vpc         = var.vpc_id
}