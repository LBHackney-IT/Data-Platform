resource "aws_glue_registry" "schema_registry" {
  registry_name = "${var.identifier_prefix}schema-registry"
  tags          = var.tags
}

resource "aws_glue_schema" "tenure_api" {
  schema_name       = "${var.identifier_prefix}tenure-api"
  registry_arn      = aws_glue_registry.schema_registry.arn
  data_format       = "AVRO"
  compatibility     = "NONE"
  tags              = var.tags
  schema_definition = file("${path.module}/schemas/tenure_api.json")
}