# AppStream Infrastructure
# AppStream Infrastructure - 10-network
appstream_azs = ["eu-west-1a", "eu-west-1b"]

appstream_cidr = "10.137.0.0/16"

appstream_tgw_subnets = ["10.137.0.0/24", "10.137.1.0/24"]

appstream_subnets  = {
    ellcexcel-stg-eu-west-1a = { availability_zone = "eu-west-1a", cidr_block = "10.137.2.0/24" }
    ellcexcel-stg-eu-west-1b = { availability_zone = "eu-west-1b", cidr_block = "10.137.3.0/24" }
    appstream-stg-eu-west-1a = { availability_zone = "eu-west-1a", cidr_block = "10.137.4.0/22" }
    appstream-stg-eu-west-1b = { availability_zone = "eu-west-1b", cidr_block = "10.137.8.0/22" }
    serverlec-stg-eu-west-1a = { availability_zone = "eu-west-1a", cidr_block = "10.137.12.0/24" }
    serverlec-stg-eu-west-1b = { availability_zone = "eu-west-1b", cidr_block = "10.137.13.0/24" }
}

appstream_security_group_ingress = [{}]

appstream_security_group_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
    description = "Allow egress anywhere."
  }
]

# Tags
application = "appstream"

automation_build_url = "https://github.com/LBHackney-IT/infrastructure/actions/workflows/project_appstream_stg.yml"

department = "appsupport"

environment = "stg"
