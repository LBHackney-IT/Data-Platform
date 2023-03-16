output "load_balancer_dns_name" {
  value = aws_alb.schema_registry.dns_name
}

output "load_balancer_security_group_id" {
  value = aws_security_group.schema_registry_alb.id
}

output "schema_registry_security_group_id" {
  value = aws_security_group.schema_registry_service.id
}
