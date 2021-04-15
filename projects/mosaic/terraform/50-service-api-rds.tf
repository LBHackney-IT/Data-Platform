module "service_api_rds" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/rds/aws"
  version   = "2.23.0"

  identifier = format("social-care-case-viewer-api-db-%s", lower(var.environment))

  engine                = "postgres"
  engine_version        = "11.10"
  instance_class        = "db.t3.medium"
  allocated_storage     = 20
  major_engine_version  = "11"

  username = "sccv_admin"
  password = aws_ssm_parameter.service_api_db_password.value
  port     = "5432"
  name     = "social_care"

  vpc_security_group_ids = [aws_security_group.service_api_rds.id]
  subnet_ids             = module.core_vpc.private_subnets

  maintenance_window = "sun:10:00-sun:10:30"
  backup_window      = "00:01-00:31"
  timezone           = "UTC"

  backup_retention_period = 30

  create_db_parameter_group = false
  create_db_option_group = false

  monitoring_interval = 0
  storage_encrypted = true

  skip_final_snapshot       = false
  deletion_protection       = true
  final_snapshot_identifier = format("social-care-case-viewer-api-db-%s-final-snapshot", lower(var.environment))

  multi_az = true

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_db_hostname" {
  provider = aws.core

  name  = format("/social-care-case-viewer-api/mosaic-%s/postgres-hostname", lower(var.environment))
  type  = "String"
  value = module.service_api_rds.this_db_instance_address

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_db_username" {
  provider = aws.core

  name  = format("/social-care-case-viewer-api/mosaic-%s/postgres-username", lower(var.environment))
  type  = "String"
  value = module.service_api_rds.this_db_instance_username

  tags = module.tags.values
}

resource "random_password" "service_api_db_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "service_api_db_password" {
  provider = aws.core

  name  = format("/social-care-case-viewer-api/mosaic-%s/postgres-password", lower(var.environment))
  type  = "SecureString"
  value = random_password.service_api_db_password.result

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_db_port" {
  provider = aws.core

  name  = format("/social-care-case-viewer-api/mosaic-%s/postgres-port", lower(var.environment))
  type  = "String"
  value = module.service_api_rds.this_db_instance_port

  tags = module.tags.values
}
