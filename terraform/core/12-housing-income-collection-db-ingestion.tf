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
  table_filter_expressions_housing_income_collection = local.is_live_environment ? "(^housingfinancedbproduction_actions$|^housingfinancedbproduction_agreements$|^housingfinancedbproduction_agreement_states$|^housingfinancedbproduction_ar_internal_metadata$|^housingfinancedbproduction_cases$|^housingfinancedbproduction_case_priorities$|^housingfinancedbproduction_court_cases$|^housingfinancedbproduction_delayed_jobs$|^housingfinancedbproduction_documents$|^housingfinancedbproduction_evictions$|^housingfinancedbproduction_agreement_legacy_migrations$|^housingfinancedbproduction_schema_migrations$|^housingfinancedbproduction_users$)" : ""
}

resource "aws_glue_trigger" "housing_income_collection_filter_ingestion_tables" {
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix}housing-income-collection-tables"
  type    = "CONDITIONAL"
  enabled = local.is_production_environment

  actions {
    job_name = module.ingest_housing_income_collection_database_to_housing_raw_zone.job_name
    arguments = {
      "--table_filter_expression" = local.table_filter_expressions_housing_income_collection
    }
  }

  predicate {
    conditions {
      crawler_name = local.is_live_environment ? module.housing_income_collection_database_ingestion[0].crawler_name : "dummy-development-crawler-name"
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "ingest_housing_income_collection_database_to_housing_raw_zone" {
  tags = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department = module.department_housing

  job_name                   = "${local.short_identifier_prefix}Housing Income Collection Database Ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  helper_module_key          = aws_s3_object.helpers.key
  jdbc_connections           = local.is_live_environment ? [module.housing_income_collection_database_ingestion[0].jdbc_connection_name] : []
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--source_data_database"        = local.is_live_environment ? module.housing_income_collection_database_ingestion[0].ingestion_database_name : ""
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/housing/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/housing/ingestion-details/"
    "--table_filter_expression"     = local.table_filter_expressions_housing_income_collection
  }
  crawler_details = {
    database_name      = module.department_housing.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/housing/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableGroupingPolicy     = "CombineCompatibleSchemas"
        TableLevelConfiguration = 3
      }
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
    })
    table_prefix = null
  }
  glue_crawler_excluded_blobs = [
    "*/mtfh*",
    "*/archive*",
    "*/data-quality*",
    "*/glue-*",
    "*/google-sheets*",
    "*/govnotify*",
    "*/ingestion-details*",
    "*/nec-migration-data-quality-tests*",
    "*/temp_backup*",
    "*.json",
    "*.txt",
    "*.zip",
    "*.xlsx",
    "*.html"
  ]
}


resource "aws_ssm_parameter" "ingest_housing_income_collection_database_to_housing_raw_zone_crawler_name" {
  tags  = module.tags.values
  name  = "/${local.identifier_prefix}/glue_crawler/housing/ingest_housing_income_collection_database_to_housing_raw_zone_crawler_name"
  type  = "String"
  value = module.ingest_housing_income_collection_database_to_housing_raw_zone.crawler_name
}
