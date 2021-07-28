# resource "aws_s3_bucket_object" "elec_mech_fire_communal_lighting_script" {
#   tags = module.tags.values
#
#   bucket = var.glue_scripts_bucket_id
#   key    = "scripts/elec_mech_fire_communal_lighting.py"
#   acl    = "private"
#   source = "../scripts/elec_mech_fire_communal_lighting.py"
#   etag   = filemd5("../scripts/elec_mech_fire_communal_lighting.py")
# }

resource "aws_glue_job" "housing_repairs_elec_mech_fire_cleaning" {
  count = var.is_live_environment ? 1 : 0

  tags = var.tags

  name              = "${var.short_identifier_prefix}Housing Repairs - Electrical Mechnical Fire Safety ${title(replace(var.dataset_name, "-", " "))} Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${var.script_key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--cleaned_repairs_s3_bucket_target" = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"
    "--source_catalog_database"          = var.catalog_database
    "--source_catalog_table"             = var.worksheet_resource.catalog_table
    "--TempDir"                          = var.glue_temp_storage_bucket_id
    "--extra-py-files"                   = "s3://${var.glue_scripts_bucket_id}/${var.helper_script_key},s3://${var.glue_scripts_bucket_id}/${var.cleaning_helper_script_key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_elec_mech_fire_cleaned_crawler" {
  count = var.is_live_environment ? 1 : 0
  tags  = var.tags

  database_name = var.refined_zone_catalog_database_name
  name          = "${var.short_identifier_prefix}refined-zone-housing-repairs-elec-mech-fire-${var.dataset_name}-cleaned"
  role          = var.glue_role_arn
  table_prefix  = "housing_repairs_elec_mech_fire_communal_lighting_"

  s3_target {
    path = "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/cleaned/"


    exclusions = var.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_cleaning_job" {
  count = var.is_live_environment ? 1 : 0
  tags  = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.worksheet_resource.workflow_name

  predicate {
    conditions {
      crawler_name = var.worksheet_resource.crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_elec_mech_fire_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_crawler" {
  count = var.is_live_environment ? 1 : 0
  tags  = var.tags

  name          = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.worksheet_resource.workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_elec_mech_fire_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_elec_mech_fire_cleaned_crawler[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_elec_mech_fire_address_cleaning" {
  count = var.is_live_environment ? 1 : 0

  name          = "${var.identifier_prefix}-housing-repairs-elec-mech-fire-${var.dataset_name}-address-cleaning-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.worksheet_resource.workflow_name
  tags          = var.tags

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_elec_mech_fire_cleaned_crawler[0].name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    arguments = {
      "--source_catalog_database" : var.refined_zone_catalog_database_name
      "--source_catalog_table" : "housing_repairs_elec_mech_fire_${replace(var.dataset_name, "-", "_")}_cleaned"
      "--cleaned_addresses_s3_bucket_target" : "s3://${var.refined_zone_bucket_id}/housing-repairs/repairs-electrical-mechanical-fire/${var.dataset_name}/with-cleaned-addresses"
      "--source_address_column_header" : "property_address"
      "--source_postcode_column_header" : "None"
    }
    job_name = var.address_cleaning_job_name
  }
}
