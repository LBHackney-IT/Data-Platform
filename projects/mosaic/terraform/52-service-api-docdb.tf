resource "aws_docdb_subnet_group" "service_api_docdb" {
  provider = aws.core

  name       = format("social-care-case-viewer-api-docdb-subnet-%s", lower(var.environment))
  subnet_ids = module.core_vpc.private_subnets

  tags = module.tags.values
}

resource "aws_docdb_cluster" "service_api_docdb" {
  provider = aws.core

  cluster_identifier = format("social-care-case-viewer-api-docdb-%s", lower(var.environment))

  engine_version = "3.6.0"

  db_subnet_group_name = aws_docdb_subnet_group.service_api_docdb.name

  master_username = "socialcareadmin"
  master_password = random_password.service_api_docdb_password.result

  port = 27017

  vpc_security_group_ids = [aws_security_group.service_api_docdb.id]

  backup_retention_period      = 7
  preferred_backup_window      = "00:01-00:31"
  preferred_maintenance_window = "sun:10:00-sun:10:30"

  skip_final_snapshot       = false
  final_snapshot_identifier = format("social-care-case-viewer-api-docdb-%s-final-snapshot", lower(var.environment))

  storage_encrypted   = true
  deletion_protection = true

  tags = module.tags.values
}

resource "aws_docdb_cluster_instance" "service_api_docdb" {
  provider = aws.core

  identifier         = format("social-care-case-viewer-api-docdb-%s", lower(var.environment))
  cluster_identifier = aws_docdb_cluster.service_api_docdb.id
  instance_class     = "db.r5.large"

  promotion_tier = 1
}

resource "random_password" "service_api_docdb_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "service_api_docdb_connection_string" {
  provider = aws.core

  name = format("/social-care-case-viewer-api/mosaic-%s/docdb-conn-string", lower(var.environment))
  type = "SecureString"
  value = format(
    "mongodb://%s:%s@%s:%s/?ssl=true&ssl_ca_certs=rds-ca-2019-root.pem",
    aws_docdb_cluster.service_api_docdb.master_username,
    aws_docdb_cluster.service_api_docdb.master_password,
    aws_docdb_cluster.service_api_docdb.endpoint,
    aws_docdb_cluster.service_api_docdb.port,
  )

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_docdb_name" {
  provider = aws.core

  name  = format("/social-care-docdb/mosaic-%s/docdb-name", lower(var.environment))
  type  = "String"
  value = "social_care_db"

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_docdb_collection" {
  provider = aws.core

  name  = format("/social-care-docdb/mosaic-%s/docdb-collection", lower(var.environment))
  type  = "String"
  value = "form_data"

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_docdb_collection_temp" {
  provider = aws.core

  name  = format("/social-care-docdb/mosaic-%s/docdb-collection-temp", lower(var.environment))
  type  = "String"
  value = "form_data_test"

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_docdb_import_collection_name" {
  provider = aws.core

  name  = format("/social-care-docdb-import/mosaic-%s/collection-name", lower(var.environment))
  type  = "String"
  value = "form_data"

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_docdb_import_file_name" {
  provider = aws.core

  name  = format("/social-care-docdb-import/mosaic-%s/file-name", lower(var.environment))
  type  = "String"
  value = "form_data.csv"

  tags = module.tags.values
}
