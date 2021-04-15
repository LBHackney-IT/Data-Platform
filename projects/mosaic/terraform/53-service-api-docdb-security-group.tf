resource "aws_security_group" "service_api_docdb" {
  provider = aws.core

  name   = "social-care-case-viewer-api-docdb-sg"
  vpc_id = module.core_vpc.vpc_id

  ingress {
    description = "Allow inbound traffic via 27017"
    from_port   = 27017
    to_port     = 27017
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
