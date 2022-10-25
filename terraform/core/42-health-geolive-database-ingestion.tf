module "health_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-health-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access boundaries layers from the health schema"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "health"
}

