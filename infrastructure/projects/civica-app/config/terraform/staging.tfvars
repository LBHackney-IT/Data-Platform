# AppStream Infrastructure
# AppStream Infrastructure - 10-network
# appstream_azs = ["eu-west-1a", "eu-west-1b"]

# appstream_cidr = "10.133.0.0/16"

# appstream_enable_nat_gateway = true

# appstream_private_subnets = ["10.133.0.0/24", "10.133.1.0/24"]

# appstream_public_subnets  = ["10.133.2.0/24", "10.133.3.0/24"]

# appstream_security_group_ingress = [{}]

# appstream_security_group_egress = [
#     {
#         from_port   = 0
#         to_port     = 0
#         protocol    = "-1"
#         description = "Allow egress anywhere."
#     }
# ]

# Core Infrastructure
# Core Infrastructure - 10-network
core_azs = ["eu-west-2a", "eu-west-2b"]

core_cidr = "10.120.25.0/24"

core_enable_nat_gateway = true

core_private_subnets = ["10.120.25.0/25"]

core_public_subnets  = ["10.120.25.128/25"]

core_security_group_ingress = [
    {
        from_port   = 21064
        to_port     = 21064
        protocol    = "TCP"
        cidr_blocks = "10.120.25.0/25"
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
environment = "stg"

key_name = "civica-app-stg"

service_name = "civica-app"

whitelist = []
