resource "aws_glue_workflow" "parking_liberator_data" {
  # This resource is modified outside of terraform by parking analysts.
  # Any change which forces the workflow to be recreated will lose their changes.
  name = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  tags = module.tags.values
}


// LIBERATOR LANDING ZONE
resource "aws_glue_catalog_database" "landing_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-landing-zone"
}

resource "aws_glue_trigger" "landing_zone_liberator_crawler_trigger" {
  tags = module.department_parking.tags

  name          = "${local.identifier_prefix} Landing Zone Liberator Crawler"
  type          = "ON_DEMAND"
  enabled       = true
  workflow_name = aws_glue_workflow.parking_liberator_data.name

  actions {
    crawler_name = aws_glue_crawler.landing_zone_liberator.name
  }
}

resource "aws_glue_crawler" "landing_zone_liberator" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_liberator.name
  name          = "${local.identifier_prefix}-landing-zone-liberator"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/parking/liberator"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

// LIBERATOR RAW ZONE

resource "aws_glue_trigger" "landing_zone_liberator_crawled" {
  tags = module.department_parking.tags

  name          = "${local.identifier_prefix} Landing Zone Liberator Crawled"
  type          = "CONDITIONAL"
  enabled       = true
  workflow_name = aws_glue_workflow.parking_liberator_data.name

  predicate {
    conditions {
      crawl_state  = "SUCCEEDED"
      crawler_name = aws_glue_crawler.landing_zone_liberator.name
    }
  }

  actions {
    job_name = aws_glue_job.copy_parking_liberator_landing_to_raw.name
  }

  actions {
    job_name = aws_glue_job.copy_env_enforcement_liberator_landing_to_raw.name
  }
}

resource "aws_glue_job" "copy_parking_liberator_landing_to_raw" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Copy parking Liberator landing zone to raw"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.copy_tables_landing_to_raw.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_bucket_target"          = module.raw_zone.bucket_id
    "--s3_prefix"                 = "parking/liberator/"
    "--table_filter_expression"   = "^liberator_(?!fpn).*"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_liberator.name
    "--glue_database_name_target" = aws_glue_catalog_database.raw_zone_liberator.name
    "--extra-py-files"            = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog"   = "true"
  }
}

resource "aws_glue_job" "copy_env_enforcement_liberator_landing_to_raw" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Copy Env Enforcement Liberator landing zone to raw"
  number_of_workers = 2
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.copy_tables_landing_to_raw.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--job-bookmark-option"       = "job-bookmark-enable"
    "--s3_bucket_target"          = module.raw_zone.bucket_id
    "--s3_prefix"                 = "env-enforcement/liberator/"
    "--table_filter_expression"   = "^liberator_fpn.*"
    "--glue_database_name_source" = aws_glue_catalog_database.landing_zone_liberator.name
    "--glue_database_name_target" = module.department_env_enforcement.raw_zone_catalog_database_name
    "--extra-py-files"            = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-glue-datacatalog"   = "true"
  }
}

resource "aws_glue_catalog_database" "raw_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-raw-zone"
}

// LIBERATOR REFINED ZONE
resource "aws_glue_catalog_database" "refined_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-refined-zone"
}

resource "aws_glue_crawler" "refined_zone_parking_liberator_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.refined_zone_liberator.name
  name          = "${local.identifier_prefix}-refined-zone-liberator"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/parking/liberator/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}