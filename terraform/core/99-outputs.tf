# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "network_vpc_arn" {
  description = "The ARN of the AWS VPC"
  value       = data.aws_vpc.network.arn
}

output "network_vpc_subnets" {
  description = "A list of AWS Subnet IDs"
  value       = toset(data.aws_subnets.network.ids)
}

output "network_vpc_subnet_cider_blocks" {
  value = [for subnet in data.aws_subnet.network : subnet.cidr_block]
}

output "liberator_dump_to_rds_snapshot_ecr_repository_worker_endpoint" {
  value = try(module.liberator_dump_to_rds_snapshot[0].ecr_repository_worker_endpoint, null)
}

output "pre_prod_data_cleanup_ecr_repository_endpoint" {
  value = try(module.pre_production_data_cleanup[0].ecr_repository_worker_endpoint, null)
}

output "ssl_connection_resources_bucket_id" {
  value = try(aws_s3_bucket.ssl_connection_resources[0].id, "")
}

output "identity_store_id" {
  value = local.identity_store_id
}

output "arn" {
  value = local.sso_instance_arn
}

output "mwaa_etl_scripts_bucket_arn" {
  value = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
}

output "mwaa_key_arn" {
  value = aws_kms_key.mwaa_key.arn
}

output "glue_data_catalog_cloudtrail_arn" {
  description = "ARN of the CloudTrail logging Glue Data Catalog usage"
  value       = aws_cloudtrail.glue_data_catalog_usage.arn
}

output "glue_data_catalog_cloudtrail_log_group" {
  description = "CloudWatch Log Group for Glue Data Catalog CloudTrail"
  value       = aws_cloudwatch_log_group.glue_data_catalog_cloudtrail.name
}
