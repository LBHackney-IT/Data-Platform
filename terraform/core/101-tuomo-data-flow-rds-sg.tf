resource "aws_security_group" "tuomo_data_flow_rds" {
  name   = "tuomo-data-flow-rds-sg"
  vpc_id = data.aws_vpc.network.id

  ingress {
    description = "Allow inbound traffic via 5432"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"

    cidr_blocks = [data.aws_vpc.network.cidr_block]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}