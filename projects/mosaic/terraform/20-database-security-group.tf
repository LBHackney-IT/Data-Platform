resource "aws_security_group" "rds_db_traffic" {
  provider = aws.core

  vpc_id      = module.core_vpc.vpc_id
  name_prefix = "allow_mosaic_db_traffic"

  ingress {
    description = "mosaic_postgres_db_${lower(var.environment)}"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    cidr_blocks = [module.core_vpc.vpc_cidr_block]
  }

  egress {
    description = "allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mosaic_db-${lower(var.environment)}"
  }
}
