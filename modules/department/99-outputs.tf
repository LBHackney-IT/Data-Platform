output "is_live_environment" {
  description = "A flag indicting if we are running in a live environment for setting up automation"
  value       = var.is_live_environment
}

output "identifier_prefix" {
  description = "Project wide resource identifier prefix"
  value       = var.identifier_prefix
}

output "name" {
  description = "The name of the department"
  value       = var.name
}

output "identifier" {
  description = "The name of the department"
  value       = local.department_identifier
}

output "landing_zone_catalog_database_name" {
  description = "Landing Zone Catalog Database Name"
  value       = aws_glue_catalog_database.landing_zone_catalog_database.name
}

output "raw_zone_catalog_database_name" {
  description = "Landing Zone Catalog Database Name"
  value       = aws_glue_catalog_database.raw_zone_catalog_database.name
}

output "refined_zone_catalog_database_name" {
  description = "Landing Zone Catalog Database Name"
  value       = aws_glue_catalog_database.refined_zone_catalog_database.name
}

output "trusted_zone_catalog_database_name" {
  description = "Trusted Zone Catalog Database Name"
  value       = aws_glue_catalog_database.trusted_zone_catalog_database.name
}

output "google_service_account" {
  description = "The service account created for this department"
  value       = module.google_service_account
}
