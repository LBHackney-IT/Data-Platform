resource "aws_s3_bucket_object" "repairs_door_entry_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_door_entry_cleaning.py"
  acl    = "private"
  source = "../scripts/repairs_door_entry_cleaning.py"
  etag   = filemd5("../scripts/repairs_door_entry_cleaning.py")
}

resource "aws_glue_job" "housing_repairs_door_entry_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs ElecMechFire Door Entry Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_door_entry_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-door-entry/cleaned"
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_door_entry"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_arn}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_door_entry_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-door-entry-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_door_entry_"


  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-door-entry/cleaned/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "housing_repairs_repairs_door_entry_cleaning_job" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-door-entry-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = "${local.identifier_prefix}housing-repairs-repairs-door-entry"


  predicate {
    conditions {
      crawler_name = "Xlsx Crawler Trigger - Electrical Mechanical Fire Safety Repairs - Door Entry"
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_door_entry_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_repairs_door_entry_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-door-entry-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = "${local.identifier_prefix}housing-repairs-repairs-door-entry"

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_door_entry_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_repairs_door_entry_cleaned_crawler.name
  }
}
