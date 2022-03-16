module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "academy-benefits-housing-needs-and-revenues"
  jdbc_connection_url         = "jdbc:sqlserver://10.120.23.22:1433;databaseName=LBHATestRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHATestRBViews database"
  jdbc_connection_subnet_id   = local.subnet_ids_list[local.subnet_ids_random_index]
  database_availability_zone  = "eu-west-2a"
  database_secret_name        = "database-credentials/lbhatestrbviews-revenue-benefits-council-tax"
  identifier_prefix           = local.short_identifier_prefix
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
  ] : []
  academy_ingestion_max_concurrent_runs = length(local.table_filter_expressions)
}

resource "aws_glue_trigger" "filter_ingestion_tables" {
  tags = module.tags.values

  for_each      = toset(local.table_filter_expressions)
  name          = "${local.short_identifier_prefix}filter-${each.value}"
  type          = "CONDITIONAL"
  workflow_name = module.academy_mssql_database_ingestion[0].workflow_name

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
  max_concurrent_runs_of_glue_job = local.is_live_environment ? local.academy_ingestion_max_concurrent_runs : 1
  create_starting_trigger         = false
  workflow_name                   = module.academy_mssql_database_ingestion[0].workflow_name
  job_parameters = {
    "--source_data_database"             = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"       = "s3://${module.landing_zone.bucket_id}/academy/"
    "--s3_ingestion_details_target"      = "s3://${module.landing_zone.bucket_id}/academy/ingestion-details/"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_id}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--extra-jars"                       = "s3://${module.glue_scripts.bucket_id}/jars/deequ-1.0.3.jar"
    "--enable-continuous-cloudwatch-log" = "true"
  }
  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_academy.name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/academy/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}

module "copy_academy_benefits_housing_needs_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name               = "${local.short_identifier_prefix}Copy Academy Benefits Housing Needs to raw zone"
  script_s3_object_key   = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment            = var.environment
  pydeequ_zip_key        = aws_s3_bucket_object.pydeequ.key
  helper_module_key      = aws_s3_bucket_object.helpers.key
  glue_role_arn          = aws_iam_role.glue_role.arn
  glue_temp_bucket_id    = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  workflow_name          = module.academy_mssql_database_ingestion[0].workflow_name
  triggered_by_crawler   = module.ingest_academy_revenues_and_benefits_housing_needs_to_landing_zone[0].crawler_name
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "benefits-housing-needs/"
    "--table_filter_expression"          = "^lbhatestrbviews_core_hb.*"
    "--glue_database_name_source"        = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target"        = module.department_benefits_and_housing_needs.raw_zone_catalog_database_name
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_id}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--extra-jars"                       = "s3://${module.glue_scripts.bucket_id}/jars/deequ-1.0.3.jar"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
  }
}

module "copy_academy_revenues_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name               = "${local.short_identifier_prefix}Copy Academy Revenues to raw zone"
  script_s3_object_key   = aws_s3_bucket_object.copy_tables_landing_to_raw.key
  environment            = var.environment
  pydeequ_zip_key        = aws_s3_bucket_object.pydeequ.key
  helper_module_key      = aws_s3_bucket_object.helpers.key
  glue_role_arn          = aws_iam_role.glue_role.arn
  glue_temp_bucket_id    = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  workflow_name          = module.academy_mssql_database_ingestion[0].workflow_name
  triggered_by_crawler   = module.ingest_academy_revenues_and_benefits_housing_needs_to_landing_zone[0].crawler_name
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "revenues/"
    "--table_filter_expression"          = "(^lbhatestrbviews_core_(?!hb).*)|(^lbhatestrbviews_current_.*)|(^lbhatestrbviews_xdbvw_.*)"
    "--glue_database_name_source"        = aws_glue_catalog_database.landing_zone_academy.name
    "--glue_database_name_target"        = module.department_revenues.raw_zone_catalog_database_name
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_id}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--extra-jars"                       = "s3://${module.glue_scripts.bucket_id}/jars/deequ-1.0.3.jar"
    "--enable-glue-datacatalog"          = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--job-bookmark-option"              = "job-bookmark-enable"
  }
}
