module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion-via-jdbc-connection"

  name                        = "academy-housing-benefits-and-revenues"
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

module "ingest_academy_revenues_and_housing_benefits_to_landing_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name               = "${local.short_identifier_prefix}Revenue & Benefits and Council Tax Database Ingestion"
  script_s3_object_key   = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment            = var.environment
  pydeequ_zip_key        = aws_s3_bucket_object.pydeequ.key
  helper_module_key      = aws_s3_bucket_object.helpers.key
  jdbc_connections       = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn          = aws_iam_role.glue_role.arn
  glue_temp_bucket_id    = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  workflow_name          = module.academy_mssql_database_ingestion[0].workflow_name
  triggered_by_crawler   = module.academy_mssql_database_ingestion[0].crawler_name
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

resource "aws_s3_bucket_object" "copy_academy_revenues_and_housing_benefits_landing_to_raw" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/copy_academy_revenues_and_housing_benefits_landing_to_raw.py"
  acl         = "private"
  source      = "../scripts/jobs/copy_academy_revenues_and_housing_benefits_landing_to_raw.py"
  source_hash = filemd5("../scripts/jobs/copy_academy_revenues_and_housing_benefits_landing_to_raw.py")
}

module "move_academy_housing_benefits_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name               = "${local.short_identifier_prefix}Copy Academy Housing and Benefits to raw zone"
  script_s3_object_key   = aws_s3_bucket_object.copy_academy_revenues_and_housing_benefits_landing_to_raw.key
  environment            = var.environment
  pydeequ_zip_key        = aws_s3_bucket_object.pydeequ.key
  helper_module_key      = aws_s3_bucket_object.helpers.key
  jdbc_connections       = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn          = aws_iam_role.glue_role.arn
  glue_temp_bucket_id    = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  workflow_name          = module.academy_mssql_database_ingestion[0].workflow_name
  triggered_by_crawler   = module.ingest_academy_revenues_and_housing_benefits_to_landing_zone[0].crawler_name
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "housing-and-benefits/"
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

module "move_academy_revenues_to_raw_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/aws-glue-job"

  job_name               = "${local.short_identifier_prefix}Copy Academy Revenues to raw zone"
  script_s3_object_key   = aws_s3_bucket_object.copy_academy_revenues_and_housing_benefits_landing_to_raw.key
  environment            = var.environment
  pydeequ_zip_key        = aws_s3_bucket_object.pydeequ.key
  helper_module_key      = aws_s3_bucket_object.helpers.key
  jdbc_connections       = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  glue_role_arn          = aws_iam_role.glue_role.arn
  glue_temp_bucket_id    = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  workflow_name          = module.academy_mssql_database_ingestion[0].workflow_name
  triggered_by_crawler   = module.ingest_academy_revenues_and_housing_benefits_to_landing_zone[0].crawler_name
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
