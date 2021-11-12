
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

## RAW ZONE

## Glue job, database and crawler
resource "aws_s3_bucket_object" "ingest_tascomi_data" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/planning/tascomi_api_ingestion.py"
  acl    = "private"
  source = "../scripts/jobs/planning/tascomi_api_ingestion.py"
  etag   = filemd5("../scripts/jobs/planning/tascomi_api_ingestion.py")
}

module "ingest_tascomi_data" {
  source = "../modules/aws-glue-job"

  department                      = module.department_planning
  number_of_workers_for_glue_job  = local.number_of_workers
  max_concurrent_runs_of_glue_job = local.max_concurrent_runs
  job_name                        = "${local.short_identifier_prefix}Ingest tascomi data"
  job_parameters = {
    "--s3_bucket_target"                 = module.raw_zone.bucket_id
    "--s3_prefix"                        = "planning/tascomi/api-responses/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog"          = "true"
    "--public_key_secret_id"             = aws_secretsmanager_secret.tascomi_api_public_key.id
    "--private_key_secret_id"            = aws_secretsmanager_secret.tascomi_api_private_key.id
    "--number_of_workers"                = local.number_of_workers
    "--target_database_name"             = aws_glue_catalog_database.raw_zone_tascomi.name
    "--enable-continuous-cloudwatch-log" = "true"
  }
  script_s3_object_key = aws_s3_bucket_object.ingest_tascomi_data.key

  crawler_details = {
    database_name      = aws_glue_catalog_database.raw_zone_tascomi.name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/planning/tascomi/api-responses/"
    table_prefix       = "api_response_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 5
      }
    })
  }
}

resource "aws_glue_catalog_database" "raw_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-raw-zone"
}

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


resource "aws_s3_bucket_object" "parse_tascomi_tables_script" {
  tags   = module.tags.values
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/planning/tascomi_parse_tables.py"
  acl    = "private"
  source = "../scripts/jobs/planning/tascomi_parse_tables.py"
  etag   = filemd5("../scripts/jobs/planning/tascomi_parse_tables.py")
}

module "parse_tascomi_tables" {
  source = "../modules/aws-glue-job"

  department = module.department_planning
  job_name   = "${local.short_identifier_prefix}Parse tascomi tables"
  job_parameters = {
    "--s3_bucket_target"        = "s3://${module.raw_zone.bucket_id}/planning/tascomi/parsed/"
    "--extra-py-files"          = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_s3_object_key = aws_s3_bucket_object.parse_tascomi_tables_script.key
  triggered_by_crawler = module.ingest_tascomi_data.crawler_name

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

## Refined zone

## Glue job, database and crawler

resource "aws_glue_catalog_database" "refined_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-refined-zone"
}


resource "aws_s3_bucket_object" "tascomi_column_type_dictionary" {
  tags   = module.tags.values
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/planning/tascomi-column-type-dictionary.json"
  acl    = "private"
  source = "../scripts/jobs/planning/tascomi-column-type-dictionary.json"
  etag   = filemd5("../scripts/jobs/planning/tascomi-column-type-dictionary.json")
}

resource "aws_s3_bucket_object" "recast_tables_script" {
  tags   = module.tags.values
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/recast_tables.py"
  acl    = "private"
  source = "../scripts/jobs/recast_tables.py"
  etag   = filemd5("../scripts/jobs/recast_tables.py")
}

module "recast_tascomi_tables" {
  source = "../modules/aws-glue-job"

  department = module.department_planning
  job_name   = "${local.short_identifier_prefix}Recast tascomi tables"
  job_parameters = {
    "--s3_bucket_target"        = "s3://${module.refined_zone.bucket_id}/planning/tascomi/"
    "--column_dict_path"        = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.tascomi_column_type_dictionary.key}"
    "--extra-py-files"          = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--table_list"              = local.table_list
  }
  script_s3_object_key = aws_s3_bucket_object.recast_tables_script.key
  triggered_by_crawler = module.parse_tascomi_tables.crawler_name

  crawler_details = {
    database_name      = aws_glue_catalog_database.refined_zone_tascomi.name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/planning/tascomi/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}
