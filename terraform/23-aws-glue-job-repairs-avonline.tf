resource "aws_s3_bucket_object" "repairs_avonline_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_avonline_cleaning.py"
  acl    = "private"
  source = "../scripts/repairs_avonline_cleaning.py"
  etag   = filemd5("../scripts/repairs_avonline_cleaning.py")
}

resource "aws_glue_job" "housing_repairs_avonline_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs Avonline Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_avonline_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-avonline/cleaned"
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_avonline"
    "--TempDir"                          = module.glue_temp_storage.bucket_url
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_avonline_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-avonline-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_avonline_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-avonline/cleaned/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "housing_repairs_repairs_avonline_cleaning_job" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-avonline-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_avonline[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      crawler_name = module.repairs_avonline[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_avonline_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_repairs_avonline_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-avonline-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_avonline[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_avonline_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_repairs_avonline_cleaned_crawler.name
  }
}
