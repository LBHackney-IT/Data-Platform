# Core Infrastructure
# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.120.29.0/24"

core_private_subnets = ["10.120.29.0/26", "10.120.29.64/26"]

core_public_subnets = ["10.120.29.128/26", "10.120.29.192/26"]

core_security_group_ingress = [
  {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "Allow DMS connections to Production APIs AWS"
    cidr_blocks = "10.120.8.0/24"
  }
]

core_security_group_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress anywhere."
  }
]

# VPC peering
production_api_vpc_cidrs = ["10.120.8.0/24", "10.120.9.0/24"]

# Platform and Service API
platform_api_id = "vgk6z55etg"

platform_api_key_id = "inxm2xdk42"

service_api_show_historic_data_feature_flag = "true"

# Tags
application = "Mosaic"

department = "Social Care"

environment = "prod"

whitelist = ["86.139.244.37/32"]

confidentiality = "Restricted"

automation_build_url = "https://github.com/LBHackney-IT/residents-social-care-platform-api/blob/main/.circleci/config.yml"
