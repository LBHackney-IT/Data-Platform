module "housing_interim_finance_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "housing-interim-finance-database"
  jdbc_connection_url         = "jdbc:sqlserver://housing-finance-sql-db-production-replica.cfem8ikpzzjl.eu-west-2.rds.amazonaws.com:1433;databaseName=sow2b"
  jdbc_connection_description = "JDBC connection to Housing Interim Finance database"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "database-credentials/SOW2b-housing-interim-finance"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false
  job_schedule                = "cron(30 6 ? * MON-FRI *)"
}

locals {
  table_filter_expressions_housing_interim_finance = local.is_live_environment ? "(^sow2b_dbo_matenancyagreement$|^sow2b_dbo_uharaction$|^sow2b_dbo_maproperty$|^sow2b_dbo_ssminitransaction$|^sow2b_dbo_uhproperty$|^sow2b_dbo_calculatedcurrentbalance$)" : ""
}

resource "aws_glue_trigger" "housing_interim_finance_filter_ingestion_tables" {
  tags    = module.tags.values
  name    = "${local.short_identifier_prefix}housing-interim-finance-tables"
  type    = "CONDITIONAL"
  enabled = local.is_production_environment

  actions {
    job_name = module.ingest_housing_interim_finance_database_to_housing_raw_zone.job_name
    arguments = {
      "--table_filter_expression" = local.table_filter_expressions_housing_interim_finance
    }
  }

  predicate {
    conditions {
      crawler_name = local.is_live_environment ? module.housing_interim_finance_database_ingestion[0].crawler_name : "dummy-development-crawler-name"
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "ingest_housing_interim_finance_database_to_housing_raw_zone" {
  tags = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department = module.department_housing

  job_name                   = "${local.short_identifier_prefix}Housing Interim Finance Database Ingestion"
  glue_version               = local.is_production_environment ? "2.0" : "4.0"
  script_s3_object_key       = aws_s3_object.ingest_database_tables_via_jdbc_connection.key
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_object.pydeequ.key
  helper_module_key          = aws_s3_object.helpers.key
  jdbc_connections           = local.is_live_environment ? [module.housing_interim_finance_database_ingestion[0].jdbc_connection_name] : []
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  job_parameters = {
    "--source_data_database"        = local.is_live_environment ? module.housing_interim_finance_database_ingestion[0].ingestion_database_name : ""
    "--s3_ingestion_bucket_target"  = "s3://${module.raw_zone.bucket_id}/housing/"
    "--s3_ingestion_details_target" = "s3://${module.raw_zone.bucket_id}/housing/ingestion-details/"
    "--table_filter_expression"     = local.table_filter_expressions_housing_interim_finance
  }
  crawler_details = {
    database_name      = module.department_housing.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/housing/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
    })
    table_prefix = null
  }
  glue_crawler_excluded_blobs = [
    "*/archive*",
    "*/data-quality*",
    "*/glue-*",
    "*/google-sheets*",
    "*/govnotify*",
    "*/housingfinance*",
    "*/ingestion-details*",
    "*/mtfh*",
    "*/temp_backup*",
    "*.json",
    "*.txt",
    "*.zip",
    "*.xlsx",
    "*.html",
  ] 
}

resource "aws_ssm_parameter" "ingest_housing_interim_finance_database_to_housing_raw_zone_crawler_name" {
  tags  = module.tags.values
  name  = "/${local.identifier_prefix}/glue_crawler/housing/ingest_housing_interim_finance_database_to_housing_raw_zone_crawler_name"
  type  = "String"
  value = module.ingest_housing_interim_finance_database_to_housing_raw_zone.crawler_name
}
