resource "aws_db_instance" "datahub" {
  allocated_storage       = 15
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t3.micro"
  username                = "datahub"
  identifier              = replace("${var.short_identifier_prefix}datahub", "-", "")
  password                = random_password.datahub_secret.result
  db_subnet_group_name    = aws_db_subnet_group.datahub.name
  vpc_security_group_ids  = [aws_security_group.datahub.id]
  skip_final_snapshot     = false
  deletion_protection     = var.is_live_environment
  backup_retention_period = 14
  backup_window           = "22:00-22:31"
  maintenance_window      = "Wed:23:13-Wed:23:43"
  ca_cert_identifier      = "rds-ca-rsa2048-g1"
  tags                    = var.tags
}

resource "aws_db_subnet_group" "datahub" {
  tags       = var.tags
  name       = "${var.short_identifier_prefix}datahub"
  subnet_ids = var.vpc_subnet_ids
}

resource "aws_security_group" "datahub" {
  name   = "${var.short_identifier_prefix}datahub"
  vpc_id = var.vpc_id

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      data.aws_vpc.vpc.cidr_block,
    ]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
