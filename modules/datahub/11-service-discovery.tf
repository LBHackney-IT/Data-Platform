resource "aws_service_discovery_private_dns_namespace" "datahub" {
  name        = "${var.operation_name}.net"
  description = "Domain for ECS service"
  vpc         = var.vpc_id
}