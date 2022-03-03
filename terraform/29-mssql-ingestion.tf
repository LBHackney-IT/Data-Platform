module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  jdbc_connection_name        = "Revenue Benefits and Council Tax"
  jdbc_connection_url         = "jdbc:sqlserver://10.120.23.22:1433;databaseName=LBHATestRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHATestRBViews database"
  jdbc_connection_subnet_id   = local.subnet_ids_list[local.subnet_ids_random_index]
  database_availability_zone  = "eu-west-2a"
  database_secret_name        = "database-credentials/lbhatestrbviews-revenue-benefits-council-tax"
  identifier_prefix           = local.short_identifier_prefix
  vpc_id                      = data.aws_vpc.network.id
}

resource "aws_glue_catalog_database" "landing_zone_academy" {
  name = "${local.short_identifier_prefix}academy-landing-zone"
}

module "ingest_lbhatestrbviews_to_landing_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name               = "${local.short_identifier_prefix}Academy lbhatestrbviews Import Job"
  script_name            = "ingest_database_tables_via_jdbc_connection"
  environment            = var.environment
  pydeequ_zip_key        = aws_s3_bucket_object.pydeequ.key
  helper_module_key      = aws_s3_bucket_object.helpers.key
  jdbc_connections       = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn          = aws_iam_role.glue_role.arn
  glue_temp_bucket_id    = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  job_parameters = {
    "--source_data_database"             = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"       = "s3://${module.landing_zone.bucket_id}/academy/"
    "--s3_ingestion_details_target"      = "s3://${module.landing_zone.bucket_id}/academy/ingestion-details/"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_id}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--extra-jars"                       = "s3://${module.glue_scripts.bucket_id}/jars/deequ-1.0.3.jar"
    "--enable-continuous-cloudwatch-log" = "true"
  }
  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_academy.name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/academy/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}
