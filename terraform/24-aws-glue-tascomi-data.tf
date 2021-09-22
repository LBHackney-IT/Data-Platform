
locals {
  number_of_workers   = 12
  max_concurrent_runs = length(local.tascomi_table_names)
  tascomi_table_names = [
    "applications",
    "contacts",
    "emails",
    "enforcements",
    "fees",
    "public_comments",
    "communications",
    "fee_payments"
  ]
}

## RAW ZONE

## Glue job, database and crawler
resource "aws_s3_bucket_object" "ingest_tascomi_data" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/tascomi_api_ingestion.py"
  acl    = "private"
  source = "../scripts/tascomi_api_ingestion.py"
  etag   = filemd5("../scripts/tascomi_api_ingestion.py")
}

resource "aws_glue_job" "ingest_tascomi_data" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix} Ingest tascomi data"
  number_of_workers = local.number_of_workers
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.ingest_tascomi_data.key}"
  }

  execution_property {
    max_concurrent_runs = local.max_concurrent_runs
  }

  glue_version = "2.0"

  default_arguments = {
    "--s3_bucket_target"        = module.raw_zone.bucket_id
    "--s3_prefix"               = "planning/tascomi/"
    "--extra-py-files"          = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog" = "true"
    "--public_key_secret_id"    = aws_secretsmanager_secret.tascomi_api_public_key.id
    "--private_key_secret_id"   = aws_secretsmanager_secret.tascomi_api_private_key.id
    "--number_of_workers"       = local.number_of_workers
    "--target_database_name"    = aws_glue_catalog_database.raw_zone_tascomi.name
  }
}

resource "aws_glue_catalog_database" "raw_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-raw-zone"
}

resource "aws_glue_crawler" "raw_zone_tascomi_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_tascomi.name
  name          = "${local.identifier_prefix}-raw-zone-tascomi"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/planning/tascomi/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

## Triggers

resource "aws_glue_trigger" "tascomi_raw_zone_crawler_trigger" {
  tags = module.tags.values

  name    = "${local.short_identifier_prefix}Tascomi Data Crawler Trigger"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      job_name = aws_glue_job.ingest_tascomi_data.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_crawler.raw_zone_tascomi_crawler.name
  }
}


resource "aws_glue_trigger" "ingest_tascomi_applications_trigger" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}Tascomi Applications Ingestion Trigger"
  type     = "ON_DEMAND"
//  schedule = "cron(0 2 * * ? *)"
//  enabled  = local.is_live_environment

  actions {
    job_name = aws_glue_job.ingest_tascomi_data.name
    arguments = {
      "--resource" = "applications"
    }
  }
}

resource "aws_glue_trigger" "ingest_tascomi_documents_trigger" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}Tascomi Documents Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 2 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    job_name = aws_glue_job.ingest_tascomi_data.name
    arguments = {
      "--resource" = "documents"
    }
  }
}

resource "aws_glue_trigger" "tascomi_tables_daily_ingestion_triggers" {
  tags = module.tags.values
  for_each = toset(local.tascomi_table_names)

  name     = "${local.short_identifier_prefix}Tascomi ${title(replace(each.value, "_", " "))} Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 3 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    job_name = aws_glue_job.ingest_tascomi_data.name
    arguments = {
      "--resource" = each.value
    }
  }
}

