resource "aws_s3_bucket_object" "housing_repairs_elec_mech_fire_fire_alarmaov_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/elec_mech_fire_fire_alarmaov_cleaning.py"
  acl    = "private"
  source = "../scripts/elec_mech_fire_fire_alarmaov_cleaning.py"
  etag   = filemd5("../scripts/elec_mech_fire_fire_alarmaov_cleaning.py")
}

resource "aws_glue_job" "housing_repairs_elec_mech_fire_fire_alarmaov_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety Fire Alarm AOV Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.housing_repairs_elec_mech_fire_fire_alarmaov_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/fire-alarmaov/cleaned/"
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = module.repairs_fire_alarm_aov[0].worksheet_resources["fire-alarmaov"].catalog_table
    "--TempDir"                          = module.glue_temp_storage.bucket_url
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_elec_mech_fire_fire_alarmaov_cleaned_crawler" {
  count = local.is_live_environment ? 1 : 0
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-elec-mech-fire-fire-alarmaov-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_elec_mech_fire_fire_alarmaov_"

  s3_target {
    path = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/fire-alarmaov/cleaned/"


    exclusions = local.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_fire_alarmaov_cleaning_job" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  name          = "${local.identifier_prefix}-housing-repairs-elec-mech-fire-fire-alarmaov-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_fire_alarm_aov[0].worksheet_resources["fire-alarmaov"].workflow_name

  predicate {
    conditions {
      crawler_name = module.repairs_fire_alarm_aov[0].worksheet_resources["fire-alarmaov"].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_elec_mech_fire_fire_alarmaov_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_fire_alarmaov_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  name          = "${local.identifier_prefix}-housing-repairs-elec-mech-fire-fire-alarmaov-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_fire_alarm_aov[0].worksheet_resources["fire-alarmaov"].workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_elec_mech_fire_fire_alarmaov_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_elec_mech_fire_fire_alarmaov_cleaned_crawler[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_fire_alarmaov_address_cleaning" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-elec-mech-fire-fire-alarmaov-address-cleaning-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_fire_alarm_aov[0].worksheet_resources["fire-alarmaov"].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_elec_mech_fire_fire_alarmaov_cleaned_crawler[0].name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    arguments = {
      "--source_catalog_database" : module.department_housing_repairs.refined_zone_catalog_database_name
      "--source_catalog_table" : "housing_repairs_elec_mech_fire_fire_alarmaov_cleaned"
      "--cleaned_addresses_s3_bucket_target" : "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/fire-alarmaov/with-cleaned-addresses"
      "--source_address_column_header" : "property_address"
      "--source_postcode_column_header" : "None"
    }
    job_name = aws_glue_job.address_cleaning[0].name
  }
}