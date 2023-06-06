resource "aws_glue_catalog_database" "raw_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-raw-zone"
}

resource "aws_ssm_parameter" "raw_zone_catalog_database_name" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/raw_zone_catalog_database_name"
  type        = "SecureString"
  description = "Raw Zone Glue Catalog Database Name"
  value       = aws_glue_catalog_database.raw_zone_catalog_database.name
}

resource "aws_glue_catalog_database" "refined_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-refined-zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "refined_zone_catalog_database_name" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/refined_zone_catalog_database_name"
  type        = "SecureString"
  description = "Refined Zone Glue Catalog Database Name"
  value       = aws_glue_catalog_database.refined_zone_catalog_database.name
}

resource "aws_glue_catalog_database" "trusted_zone_catalog_database" {
  name = "${var.short_identifier_prefix}${local.department_identifier}-trusted-zone"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "trusted_zone_catalog_database_name" {
  tags = var.tags

  name        = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/trusted_zone_catalog_database_name"
  type        = "SecureString"
  description = "Trusted Zone Glue Catalog Database Name"
  value       = aws_glue_catalog_database.trusted_zone_catalog_database.name
}
