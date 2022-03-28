output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.core_vpc.vpc_id
}

output "private_subnets_ids" {
  description = "List of private subnets IDs"
  value       = module.core_vpc.private_subnets
}
