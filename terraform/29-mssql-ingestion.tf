module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion"

  jdbc_connection_url         = "jdbc:sqlserver://127.0.0.1:1433;databaseName=LBHATestRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHATestRBViews database"
  jdbc_connection_subnet_id   = local.subnet_ids_list[local.subnet_ids_random_index]
  database_availability_zone  = "eu-west-2a"
  database_name               = "LBHATestRBViews"
  database_password           = var.academy_production_database_password
  database_username           = var.academy_production_database_username
  short_identifier_prefix     = local.short_identifier_prefix
  identifier_prefix           = local.identifier_prefix
  vpc_id                      = data.aws_vpc.network.id
}




