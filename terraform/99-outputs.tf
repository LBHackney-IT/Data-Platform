# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "email_service_accounts" {
  description = "Email service accounts"
  value = {
    housing = local.is_live_environment ? google_service_account.service_account_housing[0].email : ""
    parking = local.is_live_environment ? module.parking_google_service_account[0].email : ""
  }
}

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
  value = length(module.liberator_to_parquet) == 1 ? module.liberator_to_parquet[0].ecr_repository_worker_endpoint : null
}

output "ssl_connection_resources_bucket_id" {
  value = length(aws_s3_bucket.ssl_connection_resources) == 1 ? aws_s3_bucket.ssl_connection_resources[0].id : ""
}
