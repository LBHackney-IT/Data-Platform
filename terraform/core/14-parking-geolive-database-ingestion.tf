module "parking_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-parking-schema"
  jdbc_connection_url         = "jdbc:postgresql://geolive-db-prod.cjgyygrtgrhl.eu-west-2.rds.amazonaws.com:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access the parking schema only"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  schema_name                 = "parking"
  database_secret_name        = "database-credentials/geolive-parking"
  identifier_prefix           = local.short_identifier_prefix
  job_schedule                = "cron(0 3 ? * MON *)"
}

module "parking_geolive_ingestion_job" {
  count                     = local.is_live_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_parking
  job_name                   = "${local.short_identifier_prefix}geolive parking schema ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  helper_module_key          = aws_s3_object.helpers.key
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  jdbc_connections           = [module.parking_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler       = module.parking_geolive_database_ingestion[0].crawler_name
  workflow_name              = module.parking_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/parking/geolive/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/parking/geolive/ingestion-details/"
    "--source_data_database"        = module.parking_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.department_parking.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/parking/geolive/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
    table_prefix = null
  }
}
