resource "aws_security_group" "service_api_rds" {
  provider = aws.core

  name   = "social-care-case-viewer-api-rds-sg"
  vpc_id = module.core_vpc.vpc_id

  ingress {
    description = "Allow inbound traffic via 5432"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    cidr_blocks = [module.core_vpc.vpc_cidr_block]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = module.tags.values
}
