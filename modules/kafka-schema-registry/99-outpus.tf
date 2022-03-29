output "load_balancer_dns_name" {
  value = aws_alb.schema_registry.dns_name
}