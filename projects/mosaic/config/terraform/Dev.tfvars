# Core Infrastructure
# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.120.27.0/24"

core_private_subnets = ["10.120.27.0/26", "10.120.27.64/26"]

core_public_subnets = ["10.120.27.128/26", "10.120.27.192/26"]

core_security_group_ingress = [{}]

core_security_group_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress anywhere."
  }
]

# Tags
application = "Mosaic"

department = "Social Care"

environment = "Dev"

whitelist = []
