#setup database credentials secret
resource "random_password" "tuomo_test_db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "tuomo_test_db_credentials" {
  name = "/database-credentials/tuomo-test-db"
}

resource "aws_secretsmanager_secret_version" "tuomo_test_db_credentials" {
  secret_id     = aws_secretsmanager_secret.tuomo_test_db_credentials.id
  secret_string = jsonencode({
    username = "testdb_admin",
    password = "${random_password.tuomo_test_db_password.result}",
    database_name = "testdb"
  })
}

#get the credentials
data "aws_secretsmanager_secret" "tuomo_test_db_credentials" {
  name = "/database-credentials/tuomo-test-db"
}

data "aws_secretsmanager_secret_version" "tuomo_test_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.tuomo_test_db_credentials.id
}

locals {
  secret_string     = jsondecode(data.aws_secretsmanager_secret_version.tuomo_test_db_credentials.secret_string)
  tuomo_test_db_password = local.secret_string["password"]
}

#create subnet group for the database
resource "aws_db_subnet_group" "tuomo_test_db_subnet_group" {
  name       = "tuomo-test-db-subnet-group"
  subnet_ids = local.subnet_ids_list
}

#setup test database
#db.t2.small is the smallest instance that support encryption at rest
module "tuomo_data_flow_rds_postgres" {
  source    = "terraform-aws-modules/rds/aws"
  version   = "4.4.0"

  identifier = "tuomo-test-db"
  engine                = "postgres"
  engine_version        = "11.15"
  instance_class        = "db.t2.small" 
  allocated_storage     = 5
  max_allocated_storage = 6
  major_engine_version  = "11"

  create_random_password = false
  db_name = "testdb"
  username = "testdb_admin"
  password = local.tuomo_test_db_password
  port     = "5432"

  vpc_security_group_ids = [aws_security_group.tuomo_data_flow_rds.id]
  db_subnet_group_name = aws_db_subnet_group.tuomo_test_db_subnet_group.name

  maintenance_window = "sun:04:00-sun:04:30"
  backup_window      = "00:01-00:31"

  backup_retention_period = 1
  create_db_parameter_group = false
  create_db_option_group = false
  monitoring_interval = 0
  storage_encrypted = true
  skip_final_snapshot       = false
  deletion_protection       = false
  multi_az = false
  performance_insights_enabled = false
  publicly_accessible = false
  apply_immediately = true
}