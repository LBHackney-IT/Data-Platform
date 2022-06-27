module "social_care_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "social-care"
  jdbc_connection_url         = "jdbc:sqlserver://172.19.8.139:1433;databaseName=mosrep"
  jdbc_connection_description = "JDBC connection to mosrep database for Social Care data ingestion"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "database-credentials/mosrep-social-care"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false
}


resource "aws_glue_catalog_database" "landing_zone_social_care" {
  name = "${local.short_identifier_prefix}social-care-landing-zone"
}

// TODO: update tables to ingest once known (all)
locals {
  table_filter_expressions_social_care = local.is_live_environment ? {
    mix = "(^lbhaliverbviews_core_cr.*|^lbhaliverbviews_core_[ins].*|^lbhaliverbviews_xdbvw.*|^lbhaliverbviews_current_im.*)"
  } : {}
  social_care_ingestion_max_concurrent_runs = local.is_live_environment ? length(local.table_filter_expressions) : 1
}

resource "aws_glue_trigger" "filter_social_care_ingestion_tables" {
  for_each = local.table_filter_expressions_social_care
  tags     = module.tags.values
  name     = "${local.short_identifier_prefix}social-care-trigger-${each.key}"
  type     = "CONDITIONAL"

  actions {
    job_name = module.ingest_social_care_to_landing_zone[each.key].job_name
  }

  predicate {
    conditions {
      crawler_name = module.social_care_mssql_database_ingestion[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }
}

// firstly ingest all data as part of DPP-169
// TODO: update script to check for last 'updated_on'/ similar field - create separate ticket.
module "ingest_social_care_to_landing_zone" {
  for_each = local.table_filter_expressions_social_care
  tags     = module.tags.values

  source = "../modules/aws-glue-job"

  job_name                       = "${local.short_identifier_prefix}Social Care Database Ingestion-${each.key}"
  script_s3_object_key           = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment                    = var.environment
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  jdbc_connections               = [module.social_care_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  glue_job_timeout               = 420
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 2
  job_parameters = {
    "--source_data_database"        = module.social_care_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"  = "s3://${module.landing_zone.bucket_id}/social-care/"
    "--s3_ingestion_details_target" = "s3://${module.landing_zone.bucket_id}/social-care/ingestion-details/"
    "--table_filter_expression"     = each.value
  }
}

resource "aws_glue_crawler" "social_care_landing_zone" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_social_care.name
  name          = "${local.short_identifier_prefix}social-care-database-ingestion"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.landing_zone.bucket_id}/social-care/"
  }
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}

resource "aws_glue_trigger" "social_care_landing_zone_crawler" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}social-care-database-ingestion-crawler-trigger"
  type     = "SCHEDULED"
  schedule = "cron(15 8,12 ? * TUE *)"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.social_care_landing_zone.name
  }
}

module "copy_social_care_adult_social_care_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name                   = "${local.short_identifier_prefix}Copy Social Care Adult Social Care to raw zone"
  script_s3_object_key       = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  helper_module_key          = aws_s3_bucket_object.helpers.key
  glue_role_arn              = aws_iam_role.glue_role.arn
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  glue_job_worker_type       = "G.2X"
  glue_job_timeout           = 220
  triggered_by_crawler       = aws_glue_crawler.social_care_landing_zone.name
  job_parameters = {
    "--s3_bucket_target"          = module.raw_zone.bucket_id
    "--s3_prefix"                 = "adult-social-care/"
    "--table_filter_expression"   = "(^lbhaliverbviews_core_hb.*|^lbhaliverbviews_current_hb.*)" // to update to relevant tables
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_social_care.name
    "--glue_database_name_target" = module.department_benefits_and_housing_needs.raw_zone_catalog_database_name // to update once departments set up
    "--enable-glue-datacatalog"   = "true"
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--write-shuffle-files-to-s3" = "true"
  }
}

module "copy_scoial_care_children_family_services_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name                   = "${local.short_identifier_prefix}Copy Social Care Children and Family Services to raw zone"
  script_s3_object_key       = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  helper_module_key          = aws_s3_bucket_object.helpers.key
  glue_role_arn              = aws_iam_role.glue_role.arn
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  glue_job_timeout           = 220
  triggered_by_crawler       = aws_glue_crawler.social_care_landing_zone.name
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "children-family-services/"
    "--table_filter_expression"          = "(^lbhaliverbviews_core_(?!hb).*|^lbhaliverbviews_current_(?!hb).*|^lbhaliverbviews_xdbvw_.*)" // to update with relevant tables
    "--glue_database_name_source"        = aws_glue_catalog_database.landing_zone_social_care.name
    "--glue_database_name_target"        = module.department_revenues.raw_zone_catalog_database_name // to update once department set up
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
  }
}
