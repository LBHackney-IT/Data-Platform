module "housing_interim_finance_database_ingestion" {
  tags     = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "housing-interim-finance-database"
  jdbc_connection_url         = "jdbc:sqlserver://<HOST_IP>:<PORT>;databaseName=SOW2b"
  jdbc_connection_description = "JDBC connection to Housing Interim Finance database"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "database-credentials/sow2b-housing-interim-finance"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false  
}

locals {
  tables = local.is_live_environment ? {
    tenancy-agreement           = "MATenancyAgreement",
    uh-account-recovery-action  = "UH_Araction"
  } : {}
}

resource "aws_glue_trigger" "housing_interim_finance_filter_ingestion_tables" {
  tags     = module.tags.values
  for_each = local.tables
  name     = "${local.short_identifier_prefix}housing-interim-finance-table-${each.key}"
  type     = "CONDITIONAL"

 actions {
   job_name = module.ingest_housing_interim_finance_database_to_housing_raw_zone[each.key].job_name
   arguments = {
     "--table_filter_expression" = each.value
   }
 }

  predicate {
    conditions {
      crawler_name = module.housing_interim_finance_database_ingestion[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "ingest_housing_interim_finance_database_to_housing_raw_zone" {
  for_each = local.tables
  tags     = module.tags.values

  source = "../modules/aws-glue-job"

  department = module.department_housing

  job_name                        = "${local.short_identifier_prefix}Housing Interim Finance Database Ingestion-${each.key}"
  script_s3_object_key            = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment                     = var.environment
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  helper_module_key               = aws_s3_bucket_object.helpers.key
  jdbc_connections                = [module.housing_interim_finance_database_ingestion[0].jdbc_connection_name]
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  spark_ui_output_storage_id      = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--source_data_database"        = module.housing_interim_finance_database_ingestion[0].ingestion_database_name 
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/housing/${each.key}"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/housing/ingestion-details/"
  }
  crawler_details = {
    database_name      = module.department_housing.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/housing/${each.key}"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}
