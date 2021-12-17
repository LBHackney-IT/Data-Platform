resource "aws_glue_registry" "lbh_data_platform_schema_registry" {
  registry_name = "${var.identifier_prefix}lbh_data_platform_schema_registry"
  tags          = var.tags
}

resource "aws_glue_schema" "mmh_schema" {
  schema_name       = "${var.identifier_prefix}mmh"
  registry_arn      = aws_glue_registry.lbh_data_platform_schema_registry.arn
  data_format       = "AVRO"
  compatibility     = "NONE"
  schema_definition = "{\"type\": \"record\", \"name\": \"mmh\", \"fields\": [ {\"name\": \"f1\", \"type\": \"int\"}, {\"name\": \"f2\", \"type\": \"string\"} ]}"
  tags              = var.tags
}