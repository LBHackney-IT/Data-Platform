module "academy_mssql_database_ingestion" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  source = "../modules/database-ingestion"

  jdbc_connection_url         = "jdbc:sqlserver://10.120.23.22:1433;databaseName=LBHATestRBViews"
  jdbc_connection_description = "JDBC connection to Academy Production Insights LBHATestRBViews database"
  jdbc_connection_subnet_id   = local.subnet_ids_list[local.subnet_ids_random_index]
  database_availability_zone  = "eu-west-2a"
  database_name               = "LBHATestRBViews"
  database_password           = var.academy_production_database_password
  database_username           = var.academy_production_database_username
  identifier_prefix           = local.short_identifier_prefix
  vpc_id                      = data.aws_vpc.network.id
}

resource "aws_s3_bucket_object" "academy_get_lbhatestrbviews_core_crcheqref_table_script" {
  count = local.is_live_environment ? 1 : 0

  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/copy_all_lbhatestrbviews_tables_to_landing.py"
  acl         = "private"
  source      = "../scripts/jobs/copy_all_lbhatestrbviews_tables_to_landing.py"
  source_hash = filemd5("../scripts/jobs/copy_all_lbhatestrbviews_tables_to_landing.py")
}

resource "aws_glue_job" "copy_lbhatestrbviews_tables_to_landing_zone" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  name              = "${local.short_identifier_prefix}Academy lbhatestrbviews Import Job - all tables"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  connections       = [module.academy_mssql_database_ingestion[0].jdbc_connection_name]
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.academy_get_lbhatestrbviews_core_crcheqref_table_script[0].key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--source_data_database"             = module.academy_mssql_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target"       = "s3://${module.landing_zone.bucket_id}/academy/tables/"
    "--s3_ingestion_details_target"      = "s3://${module.landing_zone.bucket_id}/academy/tables/ingestion-details/"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_id}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--extra-jars"                       = "s3://${module.glue_scripts.bucket_id}/jars/deequ-1.0.3.jar"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}

resource "aws_glue_catalog_database" "landing_zone_academy" {
  name = "${local.short_identifier_prefix}academy-landing-zone"
}

resource "aws_glue_crawler" "landing_zone_academy" {
  tags  = module.tags.values
  count = local.is_live_environment ? 1 : 0

  name          = "${local.short_identifier_prefix}academy-landing-zone"
  database_name = aws_glue_catalog_database.landing_zone_academy.name
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/academy/tables/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}
