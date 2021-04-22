resource "aws_dms_certificate" "doc_db_certificate" {
  provider = aws.core

  certificate_id  = "mosaic-${lower(var.environment)}-doc-db-certificate"
  certificate_pem = file("${path.module}/rds-combined-ca-bundle.pem")

  tags = module.tags.values
}

# Production API Social Care DocDB details
data "aws_secretsmanager_secret" "production_api_sccv_docdb_hostname" {
  provider = aws.core

  name = "production_api_sccv_docdb_hostname"
}

data "aws_secretsmanager_secret_version" "production_api_sccv_docdb_hostname" {
  provider = aws.core

  secret_id = data.aws_secretsmanager_secret.production_api_sccv_docdb_hostname.id
}

data "aws_secretsmanager_secret" "production_api_sccv_docdb_password" {
  provider = aws.core

  name = "production_api_sccv_docdb_password"
}

data "aws_secretsmanager_secret_version" "production_api_sccv_docdb_password" {
  provider = aws.core

  secret_id = data.aws_secretsmanager_secret.production_api_sccv_docdb_password.id
}

resource "aws_dms_endpoint" "docdb_prod_apis_endpoint" {
  provider = aws.core

  database_name   = "social_care_db"
  endpoint_id     = "source-docdb-prod-api-endpoint"
  endpoint_type   = "source"
  engine_name     = "docdb"
  port            = 27017
  server_name     = data.aws_secretsmanager_secret_version.production_api_sccv_docdb_hostname.secret_string
  ssl_mode        = "verify-full"
  certificate_arn = aws_dms_certificate.doc_db_certificate.certificate_arn

  username = "socialcareadmin"
  password = data.aws_secretsmanager_secret_version.production_api_sccv_docdb_password.secret_string

  tags = merge(map("Name", "source-docdb-prod-api-endpoint"), module.tags.values)
}

# Mosaic Production Social Care DocDB details
resource "aws_dms_endpoint" "docdb_mosaic_prod_endpoint" {
  provider = aws.core

  database_name   = "social_care_db"
  endpoint_id     = "target-docdb-mosaic-prod-endpoint"
  endpoint_type   = "target"
  engine_name     = "docdb"
  port            = 27017
  server_name     = aws_docdb_cluster_instance.service_api_docdb.endpoint
  ssl_mode        = "verify-full"
  certificate_arn = aws_dms_certificate.doc_db_certificate.certificate_arn

  username = aws_docdb_cluster.service_api_docdb.master_username
  password = aws_docdb_cluster.service_api_docdb.master_password

  tags = merge(map("Name", "target-docdb-mosaic-prod-endpoint"), module.tags.values)
}

resource "aws_dms_replication_task" "docdb_prod_apis_to_docdb_mosaic_prod" {
  provider = aws.core

  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.mosaic_dms_instance.replication_instance_arn
  replication_task_id      = "docdb-prod-apis-to-docdb-mosaic-${lower(var.environment)}-dms-task"

  source_endpoint_arn = aws_dms_endpoint.docdb_prod_apis_endpoint.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.docdb_mosaic_prod_endpoint.endpoint_arn

  tags = merge(map("Name", "docdb-prod-apis-to-docdb-mosaic-${lower(var.environment)}-dms-task"), module.tags.values)

  replication_task_settings = file("${path.module}/docdb_task_settings.json")
  table_mappings            = file("${path.module}/docdb_table_mappings.json")
}
