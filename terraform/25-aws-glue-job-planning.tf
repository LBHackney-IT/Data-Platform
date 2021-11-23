locals {
  number_of_workers   = 4
  max_concurrent_runs = max(length(local.tascomi_table_names), length(local.tascomi_static_tables))
  tascomi_table_names = [
    "applications",
    "contacts",
    "emails",
    "enforcements",
    "fees",
    "public_comments",
    "communications",
    "fee_payments",
    "appeals",
    "dtf_locations",
    "documents"
  ]

  tascomi_static_tables = [
    "appeal_decision",
    "appeal_status",
    "appeal_types",
    "breach_types",
    "committees",
    "communication_templates",
    "communication_types",
    "contact_types",
    "decision_levels",
    "decision_types",
    "document_types",
    "fee_types",
    "ps_development_codes",
    "public_consultations"
  ]

  table_list = "appeals,applications,contacts,documents,dtf_locations,emails,enforcements,public_comments,communications,fee_payments,appeal_status,appeal_types,committees,communications,communication_types,contact_types,document_types,fee_types,public_consultations"

}

module "tascomi_parse_tables_increments" {
  source = "../modules/aws-glue-job"
  
  department        = module.department_planning
  job_name          = "${local.short_identifier_prefix}tascomi_parse_tables_increments_planning"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.raw_zone.bucket_id}/TEMP/increment/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_s3_object_key = aws_s3_bucket_object.tascomi_parse_tables_increments.key
  # triggered_by_crawler = module.ingest_tascomi_data.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.raw_zone_tascomi.name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/TEMP/increment/"
    table_prefix       = "increment_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
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
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/TEMP/increment/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.refined_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_s3_object_key = aws_s3_bucket_object.tascomi_recast_tables_increments.key
  triggered_by_crawler = module.tascomi_parse_tables_increments.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/TEMP/increment/"
    table_prefix       = "increment_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
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
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/TEMP/snapshot/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.refined_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_s3_object_key = aws_s3_bucket_object.tascomi_create_daily_snapshot.key
  triggered_by_crawler = module.tascomi_recast_tables_increments.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/TEMP/snapshot/"
    table_prefix       = "snapshot_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}

