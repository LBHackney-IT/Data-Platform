
locals {
  number_of_workers   = 12
  max_concurrent_runs = max(length(local.tascomi_table_names), length(local.tascomi_static_tables))
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
    "--s3_prefix"               = "planning/tascomi/api-responses/"
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
  table_prefix = "api_response_"

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/planning/tascomi/api-responses/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_trigger" "tascomi_raw_zone_crawler_trigger" {
  tags = module.tags.values

  name    = "${local.short_identifier_prefix}Tascomi Raw Zone Crawler"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      job_name = aws_glue_job.ingest_tascomi_data.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = aws_glue_crawler.raw_zone_tascomi_crawler.name
  }
}

resource "aws_glue_trigger" "tascomi_tables_daily_ingestion_triggers" {
  tags     = module.tags.values
  for_each = toset(local.tascomi_table_names)

  name     = "${local.short_identifier_prefix}Tascomi ${title(replace(each.value, "_", " "))} Ingestion Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 3 * * ? *)"
  enabled  = false

  actions {
    job_name = aws_glue_job.ingest_tascomi_data.name
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
  enabled  = false

  actions {
    job_name = aws_glue_job.ingest_tascomi_data.name
    arguments = {
      "--resource" = each.value
    }
  }
}

## Refined zone

## Glue job, database and crawler
resource "aws_s3_bucket_object" "parse_tascomi_contacts_data" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/tascomi_contacts_refinement.py"
  acl    = "private"
  source = "../scripts/tascomi_contacts_refinement.py"
  etag   = filemd5("../scripts/tascomi_contacts_refinement.py")
}

resource "aws_glue_job" "parse_tascomi_contacts_data" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix} Parse tascomi contacts data"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.parse_tascomi_contacts_data.key}"
  }


  glue_version = "2.0"

  default_arguments = {
    "--s3_bucket_target"        = "${module.refined_zone.bucket_id}/planning/tascomi/contacts/"
    "--extra-py-files"          = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = aws_glue_catalog_database.raw_zone_tascomi.name
    "--source_catalog_table"    = "contacts"

  }
}

resource "aws_glue_catalog_database" "refined_zone_tascomi" {
  name = "${local.identifier_prefix}-tascomi-refined-zone"
}

resource "aws_glue_crawler" "refined_zone_tascomi_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.refined_zone_tascomi.name
  name          = "${local.identifier_prefix}-refined-zone-tascomi"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/planning/tascomi/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "tascomi_refined_data_trigger" {
  tags = module.tags.values

  name    = "${local.short_identifier_prefix}Tascomi Refined Data Jobs Trigger"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.raw_zone_tascomi_crawler.name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.parse_tascomi_contacts_data.name
  }
}


resource "aws_glue_trigger" "tascomi_refined_zone_crawler_trigger" {
  tags = module.tags.values

  name    = "${local.short_identifier_prefix}Tascomi Refined Zone Crawler"
  type    = "CONDITIONAL"
  enabled = true

  predicate {
    conditions {
      job_name = aws_glue_job.parse_tascomi_contacts_data.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = aws_glue_crawler.refined_zone_tascomi_crawler.name
  }
}
