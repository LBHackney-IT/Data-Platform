# Shared Services Infrastructure
# Shared Services Infrastructure - 10-network
ss_primary_azs = ["eu-west-2a", "eu-west-2b"]

ss_primary_cidr = "192.168.0.0/21"

ss_primary_mgmt_subnets = ["192.168.2.0/24", "192.168.3.0/24"]

ss_primary_mgmt_subnet_tags = {
  "Type" = "Public"
  "Tier" = "Management"
}

ss_primary_tgwattach_subnets = ["192.168.6.0/24", "192.168.7.0/24"]

ss_primary_tgwattach_subnet_tags = {
  "Type" = "Private"
  "Tier" = "Tgwattach"
}

ss_primary_private_subnets = ["192.168.4.0/24", "192.168.5.0/24"]

ss_primary_private_subnet_tags = {
  "Type" = "Private"
  "Tier" = "Trust"
}

ss_primary_public_subnets = ["192.168.0.0/24", "192.168.1.0/24"]

ss_primary_public_subnet_tags = {
  "Type" = "Public"
  "Tier" = "Untrust"
}

# Shared Services Infrastructure - 11-transit-gateway
ss_primary_ram_principals = ["arn:aws:organizations::338027813792:ou/o-xel8phtnme/ou-ovxv-wmfadiiu"]

ss_secondary_ram_principals = ["arn:aws:organizations::338027813792:ou/o-xel8phtnme/ou-ovxv-wmfadiiu"]

ss_secondary_routes_tgw = ["10.137.0.0/16"]

# Tags
application = "hub"

department = "cloud-deployment"

environment = "dev"

# Palo Alto
pa_ha = "false"

key_name = "palo-alto-dev"

SSHLocation = ["213.48.4.92/32", "86.139.244.37/32"]

# extended_bootstrap = "true"
