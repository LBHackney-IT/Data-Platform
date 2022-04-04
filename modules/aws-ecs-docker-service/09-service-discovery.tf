resource "aws_service_discovery_service" "datahub" {
  name = var.container_properties.container_name

  dns_config {
    namespace_id   = var.datahub_private_dns_namespace_id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 5
  }
}