module "postgres_rds_db" {
  providers = { aws = aws.core }
  source    = "terraform-aws-modules/rds/aws"
  version   = "2.23.0"

  identifier = "mosaic-postgres"

  engine                = "postgres"
  engine_version        = "11.10"
  instance_class        = "db.m5.large"
  allocated_storage     = 80
  max_allocated_storage = 200
  major_engine_version  = "11"

  username = "mosaic"
  password = aws_secretsmanager_secret_version.postgres_db_password.secret_string
  port     = "5432"
  name     = "mosaic_postgres"

  vpc_security_group_ids = [aws_security_group.rds_db_traffic.id]
  subnet_ids             = module.core_vpc.private_subnets

  maintenance_window = "sun:10:00-sun:10:30"
  backup_window      = "00:01-00:31"
  timezone           = "UTC"

  backup_retention_period = 30

  create_db_parameter_group = false

  monitoring_interval = 0
  storage_encrypted = true

  skip_final_snapshot       = false
  deletion_protection       = true
  final_snapshot_identifier = "mosaic-postgres-before-encrypted-restore"

  snapshot_identifier = "mosaic-postgres-encrypted"

  multi_az = true

  tags = module.tags.values
}

resource "aws_secretsmanager_secret" "postgres_db_host" {
  provider = aws.core

  name = format("%s_%s_postgres_db_host", lower(var.application), lower(var.environment))
}

resource "aws_secretsmanager_secret_version" "postgres_db_host" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.postgres_db_host.id
  secret_string = module.postgres_rds_db.this_db_instance_address
}

resource "aws_secretsmanager_secret" "postgres_db_port" {
  provider = aws.core

  name = format("%s_%s_postgres_db_port", lower(var.application), lower(var.environment))
}

resource "aws_secretsmanager_secret_version" "postgres_db_port" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.postgres_db_port.id
  secret_string = module.postgres_rds_db.this_db_instance_port
}

resource "aws_secretsmanager_secret" "postgres_db_name" {
  provider = aws.core

  name = format("%s_%s_postgres_db_name", lower(var.application), lower(var.environment))
}

resource "aws_secretsmanager_secret_version" "postgres_db_name" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.postgres_db_name.id
  secret_string = module.postgres_rds_db.this_db_instance_name
}

resource "aws_secretsmanager_secret" "postgres_db_username" {
  provider = aws.core

  name = format("%s_%s_postgres_db_username", lower(var.application), lower(var.environment))
}

resource "aws_secretsmanager_secret_version" "postgres_db_username" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.postgres_db_username.id
  secret_string = module.postgres_rds_db.this_db_instance_username
}

resource "random_password" "postgres_db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "postgres_db_password" {
  provider = aws.core

  name = format("%s_%s_postgres_db_password", lower(var.application), lower(var.environment))
}

resource "aws_secretsmanager_secret_version" "postgres_db_password" {
  provider = aws.core

  secret_id     = aws_secretsmanager_secret.postgres_db_password.id
  secret_string = random_password.postgres_db_password.result
}
