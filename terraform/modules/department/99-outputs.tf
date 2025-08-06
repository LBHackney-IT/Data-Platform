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

output "identifier_snake_case" {
  description = "The name of the department in snake case"
  value       = replace(local.department_identifier, "-", "_")
}

output "raw_zone_catalog_database_name" {
  description = "Raw Zone Catalog Database Name"
  value       = aws_glue_catalog_database.raw_zone_catalog_database.name
}

output "refined_zone_catalog_database_name" {
  description = "Refined Zone Catalog Database Name"
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

output "redshift_cluster_secret" {
  description = "The redshift cluster parking secret arn"
  value       = aws_secretsmanager_secret.redshift_cluster_credentials.arn
}

output "glue_role_name" {
  description = "Name of the role used to run this departments glue scripts"
  value       = module.department_iam.glue_agent_role_name
}

output "glue_role_arn" {
  description = "ARN for the role used to run this departments glue scripts"
  value       = module.department_iam.glue_agent_role_arn
}

output "tags" {
  description = "Tags for each resource with department name"
  value       = merge(var.tags, { "PlatformDepartment" = local.department_identifier })
}

output "glue_temp_bucket" {
  description = "Bucket for glue to store temporary files"
  value       = var.glue_temp_storage_bucket
}

output "glue_scripts_bucket" {
  description = "Bucket where we store glue scripts"
  value       = var.glue_scripts_bucket
}

output "environment" {
  description = "Environment e.g. dev, stg, prod"
  value       = var.environment
}
