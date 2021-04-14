# Shared Services Infrastructure
# Shared Services Infrastructure - 10-network
ss_primary_azs = ["eu-west-2a", "eu-west-2b"]

ss_primary_cidr = "192.168.16.0/21"

ss_primary_mgmt_subnets = ["192.168.18.0/24", "192.168.19.0/24"]

ss_primary_mgmt_subnet_tags = {
  "Type" = "Public"
  "Tier" = "Management"
}

ss_primary_tgwattach_subnets = ["192.168.22.0/24", "192.168.23.0/24"]

ss_primary_tgwattach_subnet_tags = {
  "Type" = "Private"
  "Tier" = "Tgwattach"
}

ss_primary_private_subnets = ["192.168.20.0/24", "192.168.21.0/24"]

ss_primary_private_subnet_tags = {
  "Type" = "Private"
  "Tier" = "Trust"
}

ss_primary_public_subnets = ["192.168.16.0/24", "192.168.17.0/24"]

ss_primary_public_subnet_tags = {
  "Type" = "Public"
  "Tier" = "Untrust"
}

# Shared Services Infrastructure - 11-transit-gateway
ss_primary_ram_principals = ["arn:aws:organizations::338027813792:ou/o-xel8phtnme/ou-ovxv-4to9ugox"]

ss_secondary_ram_principals = ["arn:aws:organizations::338027813792:ou/o-xel8phtnme/ou-ovxv-4to9ugox"]

ss_secondary_routes_tgw = ["10.138.0.0/16", "10.132.0.0/16", "10.136.0.0/16", "10.120.14.0/24", "10.130.0.0/16"]

# Tags
application = "Hub"

department = "cloud-deployment"

environment = "Prod"

# Palo Alto
key_name = "palo-alto-prod"

SSHLocation = ["213.48.4.92/32", "86.139.244.37/32"]
