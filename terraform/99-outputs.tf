# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "email_service_account" {
  description = "Email service account for housing"
  value       = terraform.workspace == "default" ? google_service_account.service_account_housing[0].email : ""
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
  value = module.liberator_to_parquet.ecr_repository_worker_endpoint
}
