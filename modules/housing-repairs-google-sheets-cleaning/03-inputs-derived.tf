locals {
  glue_job_name                      = "${var.short_identifier_prefix}Housing Repairs - ${title(replace(var.dataset_name, "-", " "))}"
  raw_zone_catalog_database_name     = var.department.raw_zone_catalog_database_name
  refined_zone_catalog_database_name = var.department.refined_zone_catalog_database_name
}
