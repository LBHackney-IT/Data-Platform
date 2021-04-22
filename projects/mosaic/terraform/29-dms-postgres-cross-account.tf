# Production API Social Care DocDB details

data "aws_secretsmanager_secret" "production_api_sccv_postgres_hostname" {
  provider = aws.core

  name = "production_api_sccv_postgres_hostname"
}

data "aws_secretsmanager_secret_version" "production_api_sccv_postgres_hostname" {
  provider = aws.core

  secret_id = data.aws_secretsmanager_secret.production_api_sccv_postgres_hostname.id
}

data "aws_secretsmanager_secret" "production_api_sccv_postgres_password" {
  provider = aws.core

  name = "production_api_sccv_postgres_password"
}

data "aws_secretsmanager_secret_version" "production_api_sccv_postgres_password" {
  provider = aws.core

  secret_id = data.aws_secretsmanager_secret.production_api_sccv_postgres_password.id
}

resource "aws_dms_endpoint" "sccv_postgres_prod_apis_endpoint" {
  provider = aws.core

  database_name = "social_care"
  endpoint_id   = "source-sccv-postgres-endpoint"
  endpoint_type = "source"
  engine_name   = "postgres"


  ssl_mode        = "verify-full"
  certificate_arn = aws_dms_certificate.doc_db_certificate.certificate_arn

  server_name = data.aws_secretsmanager_secret_version.production_api_sccv_postgres_hostname.secret_string
  port        = 5600
  username    = "dms_endpoint_user"
  password    = data.aws_secretsmanager_secret_version.production_api_sccv_postgres_password.secret_string

  tags = merge(map("Name", "source-sccv-postgres-prod-api-endpoint"), module.tags.values)
}

# Mosaic Production Social Care DocDB details

resource "aws_dms_endpoint" "sccv_postgres_mosaic_prod_endpoint" {
  provider = aws.core

  database_name = module.service_api_rds.this_db_instance_name
  endpoint_id   = "target-sccv-postgres-endpoint"
  endpoint_type = "target"
  engine_name   = "postgres"


  ssl_mode        = "verify-full"
  certificate_arn = aws_dms_certificate.doc_db_certificate.certificate_arn

  server_name = module.service_api_rds.this_db_instance_address
  port        = module.service_api_rds.this_db_instance_port
  username    = module.service_api_rds.this_db_instance_username
  password    = module.service_api_rds.this_db_instance_password

  tags = merge(map("Name", "target-sccv-postgres-endpoint"), module.tags.values)
}

resource "aws_dms_replication_task" "postgres_prod_apis_to_postgres_mosaic_prod" {
  provider = aws.core

  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.mosaic_dms_instance.replication_instance_arn
  replication_task_id      = "postgres-prod-apis-to-postgres-mosaic-${lower(var.environment)}-dms-task"

  source_endpoint_arn = aws_dms_endpoint.sccv_postgres_prod_apis_endpoint.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.sccv_postgres_mosaic_prod_endpoint.endpoint_arn

  tags = merge(map("Name", "postgres-prod-apis-to-postgres-mosaic-${lower(var.environment)}-dms-task"), module.tags.values)

  replication_task_settings = file("${path.module}/postgres_task_settings.json")
  table_mappings            = file("${path.module}/postgres_table_mappings.json")
}
