# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.138.26.0/24"

core_enable_nat_gateway = true

core_private_subnets = ["10.138.26.0/25"]

core_public_subnets  = ["10.138.26.128/25"]

core_security_group_ingress = [
    {
        from_port   = 21064
        to_port     = 21064
        protocol    = "TCP"
        cidr_blocks = "10.138.26.0/25"
        description = "Allow Ingres from private subnets in the AppStream VPC."
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

# General

application = "qlikview-app"

department = "FinanceAndResourcesIT"

environment = "Stg"

key_name = "qlikview-app-stg"

whitelist = []

qlikview_app_instance_ami = "ami-08698c6c1186276cc"
