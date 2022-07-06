locals {
  tuomo_data_flow_table_filter_expressions_test_db = {
    person              = "^testdb.dbo.dm_persons"
  }
}

module "tuomo_data_flow_ingest_test_db_to_tuomo_landin_zone" {
  #create a job per table. Inhgesting all tables in one job is too heavy
  for_each = local.tuomo_data_flow_table_filter_expressions_test_db
  tags     = module.tags.values

  source = "../modules/aws-glue-job"
  #work out how to use departments on development (should be able to use housing for example)
  #department = module.department_housing

  job_name                   = "${local.short_identifier_prefix}Tuomo Test Database Ingestion-${each.key}"
  script_s3_object_key       = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment               = var.environment
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  helper_module_key          = aws_s3_bucket_object.helpers.key
  jdbc_connections           = [module.tuomo_testdb_database_ingestion[0].jdbc_connection_name]
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--source_data_database"        = module.tuomo_testdb_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"  = "s3://${module.landing_zone.bucket_id}/tuomo-test-db/"
    #ingestion details target must have one additional folder level in order for Athena to be able to analyse it once crawled
    #Athena uses these details for queries 
    "--s3_ingestion_details_target" = "s3://${module.landing_zone.bucket_id}/tuomo-test-db/ingestion-details/" 
    "--table_filter_expression"     = each.value
  }
#these are required since department is not provided
glue_role_arn = aws_iam_role.glue_role.arn #"global" role/resource
#glue_scripts_bucket_id = already set above
#glue_temp_bucket_id = already set above
#environment = already set above
#tags = already set above

#crawler should not be set for landing zone data, data should be available for queries from raw zone onwards only
#   crawler_details = {
#     database_name      = module.department_housing.raw_zone_catalog_database_name
#     s3_target_location = "s3://${module.raw_zone.bucket_id}/housing/"
#     configuration = jsonencode({
#       Version = 1.0
#       Grouping = {
#         TableLevelConfiguration = 3
#       }
#     })
#   }
}