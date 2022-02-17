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

module "get_lbhatestrbviews_core_crcheqref_table" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department        = module.department_data_and_insight
  job_name          = "${local.short_identifier_prefix}Get lbhatestrbviews core crcheqref table"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  glue_role_arn     = aws_iam_role.glue_role.arn
  job_parameters = {
    "--source_data_catalogue_table" = "table_lbhatestrbviews_core_crcheqref"
    "--source_data_database"        = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_target"                   = "s3://${module.refined_zone.bucket_id}/data-and-insight/lbhatestrbviews/core-crcheqref/"
  }
  script_name = "copy_lbhatestrbviews_core_crcheqref_to_landing"
  crawler_details = {
    table_prefix       = "lbhatestrbviews_"
    database_name      = module.department_data_and_insight.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/data-and-insight/lbhatestrbviews/core-crcheqref/"
  }
}
