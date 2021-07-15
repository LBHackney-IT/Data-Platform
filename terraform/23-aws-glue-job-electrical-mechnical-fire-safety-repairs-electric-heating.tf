locals {
  repair_electric_heating_output = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/electric_heating/cleaned/"
}

resource "aws_s3_bucket_object" "housing_repairs_electric_heating_cleaning" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_electric_heating_cleaning.py"
  acl    = "private"
  source = "../scripts/repairs_electric_heating_cleaning.py"
  etag   = filemd5("../scripts/repairs_electric_heating_cleaning.py")
}

resource "aws_glue_job" "housing_repairs_electric_heating_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs ElecMechFire Electric Heating Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.housing_repairs_electric_heating_cleaning.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = local.repair_electric_heating_output
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = module.repairs_fire_alarm_aov[0].worksheet_resources["electric-heating"].catalog_table
    "--TempDir"                          = module.glue_temp_storage.bucket_url
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_electric_heating_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-electric-heating-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_electric_heating_"


  s3_target {
    path       = local.repair_electric_heating_output
    exclusions = local.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_trigger" "housing_repairs_electric_heating_cleaning_job" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-electric-heating-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_fire_alarm_aov[0].worksheet_resources["electric-heating"].workflow_name
  tags          = module.tags.values


  predicate {
    conditions {
      crawler_name = module.repairs_fire_alarm_aov[0].worksheet_resources["electric-heating"].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_electric_heating_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_electric_heating_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-electric-heating-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_fire_alarm_aov[0].worksheet_resources["electric-heating"].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_electric_heating_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_electric_heating_cleaned_crawler.name
  }
}
