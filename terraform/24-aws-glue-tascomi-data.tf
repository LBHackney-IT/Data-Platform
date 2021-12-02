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
    "documents",
    "users"
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

  table_list = "appeals,applications,contacts,documents,dtf_locations,emails,enforcements,public_comments,communications,fee_payments,appeal_status,appeal_types,committees,communications,communication_types,contact_types,document_types,fee_types,public_consultations,users,ps_development_codes,decision_types,appeal_decision,fees"

}

# Database resources
resource "aws_glue_catalog_database" "raw_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-raw-zone"
}
resource "aws_glue_catalog_database" "refined_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-refined-zone"
}

# Columns type dictionary resources
resource "aws_s3_bucket_object" "tascomi_column_type_dictionary" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/planning/tascomi-column-type-dictionary.json"
  acl    = "private"
  source = "../scripts/jobs/planning/tascomi-column-type-dictionary.json"
  etag   = filemd5("../scripts/jobs/planning/tascomi-column-type-dictionary.json")
}

# Ingestion
module "ingest_tascomi_data" {
  source = "../modules/aws-glue-job"

  department                      = module.department_planning
  number_of_workers_for_glue_job  = local.number_of_workers
  max_concurrent_runs_of_glue_job = local.max_concurrent_runs
  job_name                        = "${local.short_identifier_prefix}tascomi_api_ingestion_planning"
  helper_module_key               = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--s3_bucket_target"        = module.raw_zone.bucket_id
    "--s3_prefix"               = "planning/tascomi/api-responses/"
    "--enable-glue-datacatalog" = "true"
    "--public_key_secret_id"    = aws_secretsmanager_secret.tascomi_api_public_key.id
    "--private_key_secret_id"   = aws_secretsmanager_secret.tascomi_api_private_key.id
    "--number_of_workers"       = local.number_of_workers
    "--target_database_name"    = aws_glue_catalog_database.raw_zone_tascomi.name
  }
  script_name = "tascomi_api_ingestion"
}


# Triggers for ingestion
resource "aws_glue_trigger" "tascomi_tables_daily_ingestion_triggers" {
  tags     = module.tags.values
  for_each = toset(local.tascomi_table_names)

  name     = "${local.short_identifier_prefix}Tascomi ${title(replace(each.value, "_", " "))} Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 3 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    job_name = module.ingest_tascomi_data.job_name
    arguments = {
      "--resource" = each.value
    }
  }
}

resource "aws_glue_trigger" "tascomi_tables_weekly_ingestion_triggers" {
  tags     = module.tags.values
  for_each = toset(local.tascomi_static_tables)

  name     = "${local.short_identifier_prefix}Tascomi ${title(replace(each.value, "_", " "))} Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 22 ? * SUN *)"
  enabled  = local.is_live_environment

  actions {
    job_name = module.ingest_tascomi_data.job_name
    arguments = {
      "--resource" = each.value
    }
  }
}

resource "aws_glue_crawler" "tascomi_api_response_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-api-response-crawler"
  role          = module.department_planning.glue_role_arn

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/planning/tascomi/api-responses/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_trigger" "tascomi_api_response_crawler_trigger" {
  tags     = module.tags.values

  name     = "${local.short_identifier_prefix}Tascomi API response crawler Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 4,5 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.tascomi_api_response_crawler.name
  }
}

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
  triggered_by_crawler = aws_glue_crawler.tascomi_api_response_crawler.name

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
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
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
    "--job-bookmark-option"     = "job-bookmark-enable"
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

