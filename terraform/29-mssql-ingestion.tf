module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "academy-benefits-housing-needs-and-revenues"
  jdbc_connection_url         = "jdbc:sqlserver://10.120.23.22:1433;databaseName=LBHATestRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHATestRBViews database"
  jdbc_connection_subnet_id   = local.subnet_ids_list[local.subnet_ids_random_index]
  database_availability_zone  = "eu-west-2a"
  database_secret_name        = "database-credentials/lbhatestrbviews-benefits-housing-needs-revenues"
  identifier_prefix           = local.short_identifier_prefix
  create_workflow             = false
  vpc_id                      = data.aws_vpc.network.id
}

resource "aws_glue_catalog_database" "landing_zone_academy" {
  name = "${local.short_identifier_prefix}academy-landing-zone"
}

locals {
  table_filter_expressions = local.is_live_environment ? [
    "^lbhatestrbviews_core_hbrent[s].*",
    "^lbhatestrbviews_core_hbc.*",
    "^lbhatestrbviews_core_hbrentclaim",
    "^lbhatestrbviews_core_hbrenttrans",
    "^lbhatestrbviews_core_hbrent[^tsc].*",
    "^lbhatestrbviews_core_hbmember",
    "^lbhatestrbviews_core_hbincome",
    "^lbhatestrbviews_core_hb[abdefghjklnopsw]",
    "^lbhatestrbviews_core_ct[dt].*",
    "^lbhatestrbviews_current_ctax.*",
    "^lbhatestrbviews_current_[hbn].*",
    "^lbhatestrbviews_core_ct[abcefghijklmnopqrsvw].*",
    "(^lbhatestrbviews_core_cr.*|^lbhatestrbviews_core_[ins].*|^lbhatestrbviews_xdbvw.*|^lbhatestrbviews_current_im.*)"
  ] : []
  academy_ingestion_max_concurrent_runs = local.is_live_environment ? length(local.table_filter_expressions) : 1
}



resource "aws_glue_trigger" "filter_ingestion_tables" {
  tags = module.tags.values

  for_each = toset(local.table_filter_expressions)
  name     = "${local.short_identifier_prefix}filter-${each.value}"
  type     = "CONDITIONAL"

  actions {
    job_name = module.ingest_academy_revenues_and_benefits_housing_needs_to_landing_zone[0].job_name
    arguments = {
      "--table_filter_expression" = each.value
    }
  }

  predicate {
    conditions {
      crawler_name = module.academy_mssql_database_ingestion[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }
}

module "ingest_academy_revenues_and_benefits_housing_needs_to_landing_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name                        = "${local.short_identifier_prefix}Academy Revenues & Benefits Housing Needs Database Ingestion"
  script_s3_object_key            = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment                     = var.environment
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  helper_module_key               = aws_s3_bucket_object.helpers.key
  jdbc_connections                = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  max_concurrent_runs_of_glue_job = local.academy_ingestion_max_concurrent_runs
  glue_job_timeout                = 300
  job_parameters = {
    "--source_data_database"        = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"  = "s3://${module.landing_zone.bucket_id}/academy/"
    "--s3_ingestion_details_target" = "s3://${module.landing_zone.bucket_id}/academy/ingestion-details/"
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
  schedule = "cron(0 5,6 ? * MON,TUE,WED,THU,FRI *)"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name
  }
}

module "copy_academy_benefits_housing_needs_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name                        = "${local.short_identifier_prefix}Copy Academy Benefits Housing Needs to raw zone"
  script_s3_object_key            = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment                     = var.environment
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  helper_module_key               = aws_s3_bucket_object.helpers.key
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_job_timeout                = 220
  max_concurrent_runs_of_glue_job = 2
  triggered_by_crawler            = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name
  job_parameters = {
    "--s3_bucket_target"          = module.raw_zone.bucket_id
    "--s3_prefix"                 = "benefits-housing-needs/"
    "--table_filter_expression"   = "(^lbhatestrbviews_core_hb.*|^lbhatestrbviews_current_hb.*)"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target" = module.department_benefits_and_housing_needs.raw_zone_catalog_database_name
    "--enable-glue-datacatalog"   = "true"
    "--job-bookmark-option"       = "job-bookmark-enable"
  }
}

module "copy_academy_revenues_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name                        = "${local.short_identifier_prefix}Copy Academy Revenues to raw zone"
  script_s3_object_key            = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment                     = var.environment
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  helper_module_key               = aws_s3_bucket_object.helpers.key
  glue_role_arn                   = aws_iam_role.glue_role.arn
  glue_temp_bucket_id             = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id          = module.glue_scripts.bucket_id
  glue_job_timeout                = 220
  max_concurrent_runs_of_glue_job = 2
  triggered_by_crawler            = aws_glue_crawler.academy_revenues_and_benefits_housing_needs_landing_zone.name
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "revenues/"
    "--table_filter_expression"          = "(^lbhatestrbviews_core_(?!hb).*|^lbhatestrbviews_current_(?!hb).*|^lbhatestrbviews_xdbvw_.*)"
    "--glue_database_name_source"        = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target"        = module.department_revenues.raw_zone_catalog_database_name
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
  }
}
