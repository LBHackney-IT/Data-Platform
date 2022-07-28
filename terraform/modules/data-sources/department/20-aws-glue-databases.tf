data "aws_ssm_parameter" "raw_zone_catalog_database_name" {
  name = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/raw_zone_catalog_database_name"
}

data "aws_ssm_parameter" "raw_zone_manual_catalog_database_name" {
  name = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/raw_zone_manual_catalog_database_name"
}

data "aws_ssm_parameter" "refined_zone_catalog_database_name" {
  name = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/refined_zone_catalog_database_name"
}

data "aws_ssm_parameter" "trusted_zone_catalog_database_name" {
  name = "/${var.identifier_prefix}/glue_catalog_database/${local.department_identifier}/trusted_zone_catalog_database_name"
}