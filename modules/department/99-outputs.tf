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