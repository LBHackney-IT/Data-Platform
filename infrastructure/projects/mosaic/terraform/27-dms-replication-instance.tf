resource "aws_dms_replication_subnet_group" "dms_subnet_group" {
  provider = aws.core

  replication_subnet_group_description = "Replication subnet group for Mosaic ${var.environment}"
  replication_subnet_group_id          = "dms-replication-subnet-group-mosaic-${lower(var.environment)}-dms-instance"
  subnet_ids                           = module.core_vpc.private_subnets

  tags = module.tags.values
}

resource "aws_security_group" "dms_sg" {
  provider = aws.core

  name        = "dms-instance-mosaic-${lower(var.environment)}"
  description = "Allow self traffic for DMS security group"
  vpc_id      = module.core_vpc.vpc_id

  ingress {
    description = "DMS traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Traffic from DocDB in Production APIs AWS"
    from_port       = 27017
    protocol        = "tcp"
    security_groups = ["${data.aws_secretsmanager_secret_version.production_apis_account_id.secret_string}/sg-08638a48feceefee4"]
    self            = false
    to_port         = 27017
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(map("Name", "dms-instance-mosaic-${lower(var.environment)}-sg"), module.tags.values)
}

resource "aws_dms_replication_instance" "mosaic_dms_instance" {
  provider = aws.core

  allocated_storage            = 20
  apply_immediately            = true
  auto_minor_version_upgrade   = false
  availability_zone            = "eu-west-2a"
  engine_version               = "3.4.3"
  multi_az                     = false
  preferred_maintenance_window = "sun:07:00-sun:07:30"
  publicly_accessible          = false
  replication_instance_class   = "dms.t3.small"
  replication_instance_id      = "mosaic-${lower(var.environment)}-dms-instance"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.dms_subnet_group.id
  vpc_security_group_ids       = [aws_security_group.dms_sg.id]

  tags = merge(map("Name", "mosaic-${lower(var.environment)}-dms-instance"), module.tags.values)
}
