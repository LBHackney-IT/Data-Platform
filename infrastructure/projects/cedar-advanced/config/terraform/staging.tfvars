# AppStream Infrastructure
# AppStream Infrastructure - 10-network
appstream_azs = ["eu-west-1a", "eu-west-1b"]

appstream_cidr = "10.135.0.0/16"

appstream_private_subnets = ["10.135.0.0/18", "10.135.64.0/18"]

appstream_public_subnets = ["10.135.128.0/18", "10.135.192.0/18"]

appstream_security_group_ingress = [{}]

appstream_security_group_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow egress anywhere."
  }
]

# Tags
application = "cedar-advanced"

department = "corporate-finance-systems"

environment = "stg"
