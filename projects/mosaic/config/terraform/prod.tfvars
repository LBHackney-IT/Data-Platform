# Core Infrastructure
# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.120.29.0/24"

core_private_subnets = ["10.120.29.0/26", "10.120.29.64/26"]

core_public_subnets = ["10.120.29.128/26", "10.120.29.192/26"]

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
application = "mosaic"

department = "social-care"

environment = "Prod"

whitelist = ["86.139.244.37/32"]

confidentiality = "Restricted"

automation_build_url = "https://github.com/LBHackney-IT/residents-social-care-platform-api/blob/main/.circleci/config.yml"
