output "private_subnets_ids" {
  description = "List of private subnets IDs"
  value       = module.core_vpc.private_subnets
}
