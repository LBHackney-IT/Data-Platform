module "parking_geolive_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "geolive-parking-schema"
  jdbc_connection_url         = "jdbc:postgresql://10.120.8.145:5432/geolive"
  jdbc_connection_description = "JDBC connection to Geolive PostgreSQL database, to access the parking schema only"
  jdbc_connection_subnet_id   = local.subnet_ids_list[local.subnet_ids_random_index]
  schema_name                 = "parking"
  database_availability_zone  = "eu-west-2a"
  database_secret_name        = "database-credentials/geolive-parking"
  identifier_prefix           = local.short_identifier_prefix
  vpc_id                      = data.aws_vpc.network.id
}

module "parking_geolive_ingestion_job" {
  source = "../modules/aws-glue-job"

  department  = module.parking
  job_name    = "${local.short_identifier_prefix}geolive parking schema ingestion"
  script_name = "ingest_database_tables_via_jdbc_connection"
  connections = [module.parking_geolive_database_ingestion[0].jdbc_connection_name]
  triggered_by_crawler = module.parking_geolive_database_ingestion[0].crawler_name
  workflow_name = module.parking_geolive_database_ingestion[0].workflow_name
  job_parameters = {
    "--s3_ingestion_bucket_target" = "s3://${module.raw_zone.bucket_id}/parking/geolive/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/parking/geolive/ingestion-details/"
    "--source_data_database" = module.parking_geolive_database_ingestion[0].ingestion_database_name
  }
  crawler_details = {
    database_name      = module.parking_geolive_database_ingestion[0].ingestion_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/parking/geolive/"
    configuration = jsonencode({
        Version = 1.0
        Grouping = {
            TableLevelConfiguration = 4
        }
    })
  }
}
