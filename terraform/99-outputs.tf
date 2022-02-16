# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "network_vpc_arn" {
  description = "The ARN of the AWS VPC"
  value       = data.aws_vpc.network.arn
}

output "network_vpc_subnets" {
  description = "A list of AWS Subnet IDs"
  value       = data.aws_subnet_ids.network.ids
}

output "network_vpc_subnet_cider_blocks" {
  value = [for subnet in data.aws_subnet.network : subnet.cidr_block]
}

output "ecr_repository_worker_endpoint" {
  value = try(module.liberator_dump_to_rds_snapshot[0].ecr_repository_worker_endpoint, null)
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

output "redshift_cluster_id" {
  value = try(module.redshift[0].cluster_id, "")
}

output "redshift_iam_role_arn" {
  value = try(module.redshift[0].role_arn, "")
}

output "redshift_schemas" {
  value = local.redshift_schemas
}

output "redshift_users" {
  value = local.redshift_users
}

output "mssql_connection_sg_id" {
  value = aws_security_group.mssql_connection.id
}

output "vpc_subnet_ids_object" {
  value = data.aws_subnet_ids.all
}

output "vpc_subnet_ids" {
  value = data.aws_subnet_ids.all.ids
}

output "aws_subnet_list" {
  value = local.subnet_ids_list
}

output "aws_subnet_list_first" {
  value = data.aws_subnet.each[0].arn
}