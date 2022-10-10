module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "academy-benefits-housing-needs-and-revenues"
  jdbc_connection_url         = "jdbc:sqlserver://10.120.23.22:1433;databaseName=LBHALiveRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHALiveRBViews database"
  jdbc_connection_subnet      = data.aws_subnet.network[local.instance_subnet_id]
  database_secret_name        = "database-credentials/lbhaliverbviews-benefits-housing-needs-revenues"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false
}

resource "aws_glue_catalog_database" "landing_zone_academy" {
  name = "${local.short_identifier_prefix}academy-landing-zone"

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  table_filter_expressions = local.is_live_environment ? {
    core_hbrent_s    = "^lbhaliverbviews_core_hbrent[s].*",
    core_hbrent_hbc  = "^lbhaliverbviews_core_hbc.*",
    core_hbrentclaim = "^lbhaliverbviews_core_hbrentclaim",
    core_hbrenttrans = "^lbhaliverbviews_core_hbrenttrans",
    core_hbrent_tsc  = "^lbhaliverbviews_core_hbrent[^tsc].*",
    core_hbmember    = "^lbhaliverbviews_core_hbmember",
    core_hbincome    = "^lbhaliverbviews_core_hbincome",
    core_hb          = "^lbhaliverbviews_core_hb[abdefghjklnopsw]",
    core_ct_dt       = "^lbhaliverbviews_core_ct[dt].*",
    current_ctax     = "^lbhaliverbviews_current_ctax.*",
    current_hbn      = "^lbhaliverbviews_current_[hbn].*",
    core_ct          = "^lbhaliverbviews_core_ct[abcefghijklmnopqrsvw].*",
    mix              = "(^lbhaliverbviews_core_cr.*|^lbhaliverbviews_core_[ins].*|^lbhaliverbviews_xdbvw.*|^lbhaliverbviews_current_im.*)"
  } : {}
  academy_ingestion_max_concurrent_runs = local.is_live_environment ? length(local.table_filter_expressions) : 1
}

resource "aws_glue_trigger" "filter_ingestion_tables" {
  for_each = local.table_filter_expressions
  tags     = module.tags.values
  name     = "${local.short_identifier_prefix}academy_revs_and_bens_ingestion_trigger-${each.key}"
  type     = "CONDITIONAL"
  enabled  = local.is_production_environment

  actions {
    job_name = module.ingest_academy_revenues_and_benefits_housing_needs_to_landing_zone[each.key].job_name
  }

  predicate {
    conditions {
      crawler_name = module.academy_mssql_database_ingestion[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "ingest_academy_revenues_and_benefits_housing_needs_to_landing_zone" {
  for_each = local.table_filter_expressions
  tags     = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  job_name                       = "${local.short_identifier_prefix}Academy Revs & Bens Housing Needs Database Ingestion-${each.key}"
  script_s3_object_key           = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment                    = var.environment
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  jdbc_connections               = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  glue_job_timeout               = 420
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 2
  job_parameters = {
    "--source_data_database"        = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"  = "s3://${module.landing_zone.bucket_id}/academy/"
    "--s3_ingestion_details_target" = "s3://${module.landing_zone.bucket_id}/academy/ingestion-details/"
    "--table_filter_expression"     = each.value
  }
}

resource "aws_glue_crawler" "academy_revenues_and_benefits_housing_needs_landing_zone" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_academy.name
  name          = "${local.short_identifier_prefix}academy-revenues-benefits-housing-needs-database-ingestion"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.landing_zone.bucket_id}/academy/"
  }
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}

resource "aws_glue_trigger" "academy_revenues_and_benefits_housing_needs_landing_zone_crawler" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}academy-revenues-benefits-housing-needs-database-ingestion-crawler-trigger"
  type     = "SCHEDULED"
  schedule = "cron(15 8,12 ? * MON,TUE,WED,THU,FRI *)"
  enabled  = local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name
  }
}

module "copy_academy_benefits_housing_needs_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  job_name                       = "${local.short_identifier_prefix}Copy Academy Benefits Housing Needs to raw zone"
  script_s3_object_key           = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment                    = var.environment
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  glue_job_worker_type           = "G.2X"
  number_of_workers_for_glue_job = 10
  glue_job_timeout               = 220
  triggered_by_crawler           = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name
  job_parameters = {
    "--s3_bucket_target"           = module.raw_zone.bucket_id
    "--s3_prefix"                  = "benefits-housing-needs/"
    "--table_filter_expression"    = "(^lbhaliverbviews_core_hb.*|^lbhaliverbviews_current_hb.*)"
    "--glue_database_name_source"  = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target"  = module.department_benefits_and_housing_needs.raw_zone_catalog_database_name
    "--enable-glue-datacatalog"    = "true"
    "--job-bookmark-option"        = "job-bookmark-enable"
    "--write-shuffle-files-to-s3"  = "true"
    "--write-shuffle-spills-to-s3" = "true"
  }
}

module "copy_academy_revenues_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  job_name                       = "${local.short_identifier_prefix}Copy Academy Revenues to raw zone"
  script_s3_object_key           = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment                    = var.environment
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  glue_job_worker_type           = "G.2X"
  number_of_workers_for_glue_job = 10
  glue_job_timeout               = 220
  triggered_by_crawler           = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "revenues/"
    "--table_filter_expression"          = "(^lbhaliverbviews_core_(?!hb).*|^lbhaliverbviews_current_(?!hb).*|^lbhaliverbviews_xdbvw_.*)"
    "--glue_database_name_source"        = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target"        = module.department_revenues.raw_zone_catalog_database_name
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--write-shuffle-files-to-s3"        = "true"
    "--write-shuffle-spills-to-s3"       = "true"
  }
}
