module "tuomo_testdb_database_ingestion" {
  count = 1
  tags = module.tags.values
  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "test-db"
  jdbc_connection_url         = "jdbc:postgresql://tuomo-test-db.cvtofzh2smx4.eu-west-2.rds.amazonaws.com:5432/testdb"
  jdbc_connection_description = "JDBC connection to tuomo test database"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "/database-credentials/tuomo-test-db"
  identifier_prefix           = local.short_identifier_prefix
  schema_name                = "dbo"
  create_workflow             = false
}
