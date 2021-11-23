module "tascomi_parse_tables_increments" {
  source = "../modules/aws-glue-job"

  department        = module.department_planning
  job_name          = "${local.short_identifier_prefix}tascomi_parse_tables_increments_planning"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.raw_zone.bucket_id}/planning/tascomi/parsed/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_name = "tascomi_parse_tables_increments"
  # triggered_by_crawler = module.ingest_tascomi_data.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.raw_zone_tascomi.name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/planning/tascomi/parsed/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
  }
}

module "tascomi_recast_tables_increments" {
  source = "../modules/aws-glue-job"

  department        = module.department_planning
  job_name          = "${local.short_identifier_prefix}tascomi_recast_tables_increments_planning"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--column_dict_path"        = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.tascomi_column_type_dictionary.key}"
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/planning/tascomi/increment/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.refined_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_name = "tascomi_recast_tables_increments"
  triggered_by_crawler = module.tascomi_parse_tables_increments.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/planning/tascomi/increment/"
    table_prefix       = "increment_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
  }
}

module "tascomi_create_daily_snapshot" {
  source = "../modules/aws-glue-job"

  department        = module.department_planning
  job_name          = "${local.short_identifier_prefix}tascomi_create_daily_snapshot_planning"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/planning/tascomi/snapshot/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.refined_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_name = "tascomi_create_daily_snapshot"
  triggered_by_crawler = module.tascomi_recast_tables_increments.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/planning/tascomi/snapshot/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
  }
}

