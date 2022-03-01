data "aws_secretsmanager_secret" "database_credentials" {
  name = var.database_secret_name
}

data "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = data.aws_secretsmanager_secret.database_credentials.id
}

locals {
  secret_string = jsondecode(data.aws_secretsmanager_secret_version.database_credentials.secret_string)
  database_username = local.secret_string["username"]
  database_password = local.secret_string["password"]
  database_name = local.secret_string["database_name"]
}

resource "aws_glue_connection" "ingestion_database" {
  tags = var.tags

  name        = "${var.identifier_prefix}${local.database_name_lowercase}-connection"
  description = var.jdbc_connection_description
  connection_properties = {
    JDBC_CONNECTION_URL = var.jdbc_connection_url
    PASSWORD            = local.database_password
    USERNAME            = local.database_username
  }

  physical_connection_requirements {
    availability_zone      = var.database_availability_zone
    security_group_id_list = [aws_security_group.ingestion_database_connection.id]
    subnet_id              = var.jdbc_connection_subnet_id
  }
}

resource "aws_security_group" "ingestion_database_connection" {
  tags = var.tags

  name   = "${var.identifier_prefix}${local.database_name_lowercase}-connection-sg"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingestion_database_connection_allow_tcp_ingress" {
  type              = "ingress"
  description       = "Self referencing rule"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.ingestion_database_connection.id
  self              = true
}

resource "aws_security_group_rule" "ingestion_database_connection_allow_tcp_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.ingestion_database_connection.id
}
