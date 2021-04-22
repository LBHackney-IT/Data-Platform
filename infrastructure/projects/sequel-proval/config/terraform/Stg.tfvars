# AppStream Infrastructure
# AppStream Infrastructure - 10-network
appstream_azs = ["eu-west-1a", "eu-west-1b"]

appstream_cidr = "10.143.0.0/16"

appstream_private_subnets = ["10.143.0.0/24", "10.143.1.0/24"]

appstream_public_subnets  = ["10.143.2.0/24", "10.143.3.0/24"]

appstream_security_group_ingress = [
    {
        from_port   = 0
        to_port     = 0
        protocol    = "TCP"
        cidr_blocks = "10.144.26.0/24"
        description = "Allow Ingress from Core VPC."
    }
]

appstream_security_group_egress = [
    {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = "0.0.0.0/0"
        description = "Allow egress anywhere."
    }
]

# Core Infrastructure
# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.144.26.0/24"

core_private_subnets = ["10.144.26.0/25"]

core_public_subnets  = ["10.144.26.128/25"]

core_security_group_ingress = [
    {
        from_port   = 0
        to_port     = 0
        protocol    = "TCP"
        cidr_blocks = "10.143.0.0/16"
        description = "Allow Ingress from Appstream VPC."
    }
]

core_security_group_egress = [
    {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = "0.0.0.0/0"
        description = "Allow egress anywhere."
    }
]

# General
application = "sequel-proval"

department = "corporate"

environment = "stg"

#whitelist = []
