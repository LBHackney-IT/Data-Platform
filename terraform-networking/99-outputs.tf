output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.core_vpc.vpc_id
}

output "private_subnets_ids" {
  description = "List of private subnets IDs"
  value       = module.core_vpc.private_subnets
}

#output "api_vpc_peer_requester_connection_id" {
#  value       = module.vpc_peering_cross_account.requester_connection_id
#  description = "Requester VPC peering connection ID"
#}
#
#output "api_vpc_peer_requester_accept_status" {
#  value       = module.vpc_peering_cross_account.requester_accept_status
#  description = "Requester VPC peering connection request status"
#}
#
#output "api_vpc_peer_accepter_connection_id" {
#  value       = module.vpc_peering_cross_account.accepter_connection_id
#  description = "Accepter VPC peering connection ID"
#}
#
#output "api_vpc_peer_accepter_accept_status" {
#  value       = module.vpc_peering_cross_account.accepter_accept_status
#  description = "Accepter VPC peering connection request status"
#}
