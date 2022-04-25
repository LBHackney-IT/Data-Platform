resource "aws_cloudwatch_log_group" "kafka_schema_registry" {
  tags = var.tags
  name = "/${var.identifier_prefix}ecs/kafka-schema-registry"
}
