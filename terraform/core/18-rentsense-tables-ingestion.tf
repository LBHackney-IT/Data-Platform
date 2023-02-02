locals {
  number_of_workers_for_mtfh_rentsense_ingestion = 16
}

module "ingest_mtfh_rentsense_tables" {
  count                     = local.is_live_environment ? 1 : 0
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  environment               = var.environment
  tags                      = module.tags.values
  glue_role_arn             = aws_iam_role.glue_role.arn

  job_name                       = "${local.short_identifier_prefix}Ingest MTFH Rentsense tables"
  job_description                = "Ingest all tables from MTFH for Rentsense from the Housing Dynamo DB instances"
  script_s3_object_key           = aws_s3_bucket_object.dynamodb_tables_ingest.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  glue_version                   = "4.0"
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  number_of_workers_for_glue_job = local.number_of_workers_for_mtfh_rentsense_ingestion
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  schedule                       = "cron(30 5 ? * MON-FRI *)"
  job_parameters = {
    "--table_names"       = "TenureInformation,Persons,ContactDetails,Assets,Accounts,EqualityInformation,HousingRegister,HousingRepairsOnline,PatchesAndAreas,Processes", # This is a comma delimited list of Dynamo DB table names to be imported
    "--role_arn"          = data.aws_ssm_parameter.role_arn_to_access_housing_tables.value
    "--s3_target"         = "s3://${module.landing_zone.bucket_id}/mtfh/"
    "--number_of_workers" = local.number_of_workers_for_mtfh_ingestion
  }

  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_catalog_database.name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/mtfh/"
    table_prefix       = "mtfh_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}

module "copy_mtfh_rentsense_dynamo_db_tables_to_raw_zone" {
  tags = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  job_name                   = "${local.short_identifier_prefix}Copy MTFH Dynamo DB tables for Rentsense to housing department raw zone"
  department                 = module.department_housing
  script_s3_object_key       = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  helper_module_key          = aws_s3_bucket_object.helpers.key
  glue_role_arn              = aws_iam_role.glue_role.arn
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  triggered_by_crawler       = module.ingest_mtfh_rentsense_tables.crawler_name
  job_parameters = {
    "--s3_bucket_target"          = module.raw_zone.bucket_id
    "--table_filter_expression"   = "(^mtfh_tenureinformation|^mtfh_assets|^mtfh_persons|^mtfh_contactdetails|^mtfh_accounts|^mtfh_equalityinformation|^mtfh_housingregister|^mtfh_housingrepairsonline|^mtfh_patchesandareas|^mtfh_processes)"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_catalog_database.name
    "--enable-glue-datacatalog"   = "true"
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_prefix"                 = "housing/"
    "--glue_database_name_target" = module.department_housing.raw_zone_catalog_database_name
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
  }
}

resource "aws_ssm_parameter" "copy_mtfh_dynamo_db_rentsense_tables_to_raw_zone_crawler_name" {
  tags  = module.tags.values
  name  = "/${local.identifier_prefix}/glue_crawler/housing/copy_mtfh_dynamo_db_rentsense_tables_to_raw_zone_crawler_name"
  type  = "String"
  value = module.copy_mtfh_rentsense_dynamo_db_tables_to_raw_zone.crawler_name
}
