module "boundaries_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-boundaries-schema"
  jdbc_connection_url         = "jdbc:postgresql://10.120.8.145:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access the boundaries schema only"
  jdbc_connection_subnet_id      = local.subnet_ids_list[local.subnet_ids_random_index]
  database_availability_zone  = "eu-west-2a"
  vpc_id                      = data.aws_vpc.network.id
  identifier_prefix           = local.short_identifier_prefix
  database_secret_name        = "database-credentials/geolive-boundaries"
  schema_name                 = "boundaries"
}

