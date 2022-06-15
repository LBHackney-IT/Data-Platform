module "housing_income_collection_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "housing-income-collection-database"
  jdbc_connection_url         = "jdbc:mysql://housing-finance-db-production-replica.cfem8ikpzzjl.eu-west-2.rds.amazonaws.com:3306/housingfinancedbproduction"
  jdbc_connection_description = "JDBC connection to Housing Income Collection database"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "database-credentials/housingfinancedbproduction-housing-income-collection"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false
}

locals {
  table_filter_expressions_housing_income_collection = local.is_live_environment ? {
    case-priorities = "^housingfinancedbproduction_case_priorities",
    agreements      = "^housingfinancedbproduction_agreements"
  } : {}
}

resource "aws_glue_trigger" "housing_income_collection_filter_ingestion_tables" {
  tags     = module.tags.values
  for_each = local.table_filter_expressions_housing_income_collection
  name     = "${local.short_identifier_prefix}housing-income-collection-table-${each.key}"
  type     = "CONDITIONAL"

  actions {
    job_name = module.ingest_housing_income_collection_database_to_housing_raw_zone[each.key].job_name
    arguments = {
      "--table_filter_expression" = each.value
    }
  }

  predicate {
    conditions {
      crawler_name = module.housing_income_collection_database_ingestion[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "ingest_housing_income_collection_database_to_housing_raw_zone" {
  for_each = local.table_filter_expressions_housing_income_collection
  tags     = module.tags.values

  source = "../modules/aws-glue-job"

  department = module.department_housing

  job_name                   = "${local.short_identifier_prefix}Housing Income Collection Database Ingestion-${each.key}"
  script_s3_object_key       = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  helper_module_key          = aws_s3_bucket_object.helpers.key
  jdbc_connections           = [module.housing_income_collection_database_ingestion[0].jdbc_connection_name]
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--source_data_database"        = module.housing_income_collection_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/housing/${each.key}"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/housing/ingestion-details/"
    "--table_filter_expression"     = each.value
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
