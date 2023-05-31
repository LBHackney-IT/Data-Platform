locals {
  number_of_workers                     = 4
  tascomi_ingestion_max_concurrent_runs = max(length(local.tascomi_table_names), length(local.tascomi_static_tables))
  tascomi_table_names = [
    "appeals",
    "applications",
    "asset_constraints",
    "communications",
    "contacts",
    "documents",
    "dtf_locations",
    "emails",
    "enforcements",
    "fee_payments",
    "fees",
    "public_comments",
    "users",
    "committee_application_map",
    "user_teams",
    "user_team_map",
    "pre_applications"
  ]

  tascomi_static_tables = [
    "appeal_decision",
    "appeal_status",
    "appeal_types",
    "application_types",
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
    "public_consultations",
    "pre_application_categories"
  ]

  table_list = join(",", concat(local.tascomi_table_names, local.tascomi_static_tables))

}

# Database resources
resource "aws_glue_catalog_database" "raw_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-raw-zone"

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_glue_catalog_database" "refined_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-refined-zone"

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_glue_catalog_database" "trusted_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-trusted-zone"

  lifecycle {
    prevent_destroy = true
  }
}

# Columns type dictionary resources
resource "aws_s3_bucket_object" "tascomi_column_type_dictionary" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/planning/tascomi-column-type-dictionary.json"
  acl         = "private"
  source      = "../../scripts/jobs/planning/tascomi-column-type-dictionary.json"
  source_hash = filemd5("../../scripts/jobs/planning/tascomi-column-type-dictionary.json")
}

# Ingestion
module "ingest_tascomi_data" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                      = module.department_planning_data_source
  number_of_workers_for_glue_job  = local.number_of_workers
  max_concurrent_runs_of_glue_job = local.tascomi_ingestion_max_concurrent_runs
  job_name                        = "${local.short_identifier_prefix}tascomi_api_ingestion_planning"
  helper_module_key               = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--s3_bucket_target"        = module.raw_zone_data_source.bucket_id
    "--s3_prefix"               = "planning/tascomi/api-responses/"
    "--enable-glue-datacatalog" = "true"
    "--public_key_secret_id"    = data.aws_secretsmanager_secret.tascomi_api_public_key.id
    "--private_key_secret_id"   = data.aws_secretsmanager_secret.tascomi_api_private_key.id
    "--number_of_workers"       = local.number_of_workers
    "--target_database_name"    = aws_glue_catalog_database.raw_zone_tascomi.name
  }
  script_name                = "tascomi_api_ingestion"
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
}


# Triggers for ingestion
resource "aws_glue_trigger" "tascomi_tables_daily_ingestion_triggers" {
  tags     = module.tags.values
  for_each = toset(local.tascomi_table_names)

  name     = "${local.short_identifier_prefix}Tascomi ${title(replace(each.value, "_", " "))} Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 2 * * ? *)"
  enabled  = local.is_production_environment

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
  enabled  = local.is_production_environment

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
  role          = module.department_planning_data_source.glue_role_arn

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/planning/tascomi/api-responses/"
  }
  table_prefix = "api_response_"
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_trigger" "tascomi_api_response_crawler_trigger" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}Tascomi API response crawler Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 4 * * ? *)"
  enabled  = local.is_production_environment

  actions {
    crawler_name = aws_glue_crawler.tascomi_api_response_crawler.name
  }
}

module "tascomi_parse_tables_increments" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_planning_data_source
  job_name                   = "${local.short_identifier_prefix}tascomi_parse_tables_increments_planning"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.raw_zone_data_source.bucket_id}/planning/tascomi/parsed/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--table_list"              = local.table_list
    "--deequ_metrics_location"  = "s3://${module.raw_zone_data_source.bucket_id}/quality-metrics/department=planning/dataset=tascomi/deequ-metrics.json"
  }
  script_name          = "tascomi_parse_tables_increments"
  triggered_by_crawler = aws_glue_crawler.tascomi_api_response_crawler.name

  crawler_details = {
    database_name      = aws_glue_catalog_database.raw_zone_tascomi.name
    s3_target_location = "s3://${module.raw_zone_data_source.bucket_id}/planning/tascomi/parsed/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}

module "tascomi_recast_tables_increments" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_planning_data_source
  job_name                   = "${local.short_identifier_prefix}tascomi_recast_tables_increments_planning"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--column_dict_path"        = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_bucket_object.tascomi_column_type_dictionary.key}"
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/planning/tascomi/increment/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_name          = "tascomi_recast_tables_increments"
  triggered_by_crawler = module.tascomi_parse_tables_increments.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/planning/tascomi/increment/"
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
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  department                = module.department_planning_data_source

  job_name                       = "${local.short_identifier_prefix}tascomi_create_daily_snapshot_planning"
  glue_job_worker_type           = "G.2X"
  number_of_workers_for_glue_job = 8
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/planning/tascomi/snapshot/"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.refined_zone_tascomi.name
    "--table_list"              = local.table_list
    "--deequ_metrics_location"  = "s3://${module.refined_zone_data_source.bucket_id}/quality-metrics/department=planning/dataset=tascomi/deequ-metrics.json"
  }
  script_name          = "tascomi_create_daily_snapshot"
  triggered_by_crawler = module.tascomi_recast_tables_increments.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone_data_source.bucket_id}/planning/tascomi/snapshot/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
    table_prefix = null
  }
}

module "tascomi_applications_to_trusted" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                     = module.department_planning_data_source
  job_name                       = "${local.short_identifier_prefix}tascomi_applications_trusted"
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 8
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"                    = "job-bookmark-enable"
    "--target_destination"                     = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/applications"
    "--enable-glue-datacatalog"                = "true"
    "--source_catalog_database"                = aws_glue_catalog_database.refined_zone_tascomi.name
    "--source_catalog_table_applications"      = "applications"
    "--source_catalog_table_application_types" = "application_types"
    "--source_catalog_table_ps_codes"          = "ps_development_codes"
    "--bank_holiday_list_path"                 = "s3://${module.raw_zone_data_source.bucket_id}/unrestricted/util/hackney_bank_holiday.csv"
  }
  script_name          = "tascomi_applications_trusted"
  triggered_by_crawler = module.tascomi_create_daily_snapshot.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.trusted_zone_tascomi.name
    s3_target_location = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/applications"
    configuration      = null
    table_prefix       = null
  }
}

module "tascomi_officers_teams_to_trusted" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_planning_data_source
  job_name                   = "${local.short_identifier_prefix}tascomi_officers_trusted"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/officers"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.refined_zone_tascomi.name
    "--source_catalog_table"    = "users"
    "--source_catalog_table2"   = "user_team_map"
    "--source_catalog_table3"   = "user_teams"
  }
  script_name          = "tascomi_officers_trusted"
  triggered_by_crawler = module.tascomi_create_daily_snapshot.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.trusted_zone_tascomi.name
    s3_target_location = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/officers"
    configuration      = null
    table_prefix       = null
  }

}

module "tascomi_locations_to_trusted" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_planning_data_source
  job_name                   = "${local.short_identifier_prefix}tascomi_locations_trusted"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"         = "job-bookmark-enable"
    "--s3_bucket_target"            = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/locations"
    "--enable-glue-datacatalog"     = "true"
    "--source_catalog_database"     = aws_glue_catalog_database.refined_zone_tascomi.name
    "--source_catalog_unrestricted" = module.department_unrestricted_data_source.trusted_zone_catalog_database_name
    "--source_catalog_table"        = "dtf_locations"
    "--source_catalog_table2"       = "latest_llpg"
  }
  script_name          = "tascomi_locations_trusted"
  triggered_by_crawler = module.tascomi_create_daily_snapshot.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.trusted_zone_tascomi.name
    s3_target_location = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/locations"
    configuration      = null
    table_prefix       = null
  }

}

module "tascomi_subsidiary_tables_to_trusted" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_planning_data_source
  job_name                   = "${local.short_identifier_prefix}tascomi_subsidiary_tables_trusted"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_bucket_target"          = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/"
    "--enable-glue-datacatalog"   = "true"
    "--source_catalog_database"   = aws_glue_catalog_database.refined_zone_tascomi.name
    "--source_catalog_table_list" = "decision_levels,decision_types,ps_development_codes,contacts"
  }
  script_name          = "tascomi_subsidiary_tables_trusted"
  triggered_by_crawler = module.tascomi_create_daily_snapshot.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.trusted_zone_tascomi.name
    s3_target_location = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/"
    configuration      = null
    table_prefix       = null
  }
}
