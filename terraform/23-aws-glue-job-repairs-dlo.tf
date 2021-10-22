resource "aws_s3_bucket_object" "housing_repairs_dlo_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_dlo_cleaning.py"
  acl    = "private"
  source = "../scripts/repairs_dlo_cleaning.py"
  etag   = filemd5("../scripts/repairs_dlo_cleaning.py")
}

module "housing_repairs_dlo_cleaning_job" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department = module.department_housing_repairs
  job_name   = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Cleaning"
  job_parameters = {
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_dlo"
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned"
    "--TempDir"                          = module.glue_temp_storage.bucket_url
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
  script_name            = aws_s3_bucket_object.housing_repairs_dlo_cleaning_script.key
  workflow_name          = module.repairs_dlo[0].workflow_name
  triggered_by_crawler   = module.repairs_dlo[0].crawler_name
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  crawler_details = {
    database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned/"
  }
}

module "housing_repairs_dlo_address_cleaning_job" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department = module.department_housing_repairs
  job_name   = "${local.short_identifier_prefix}DLO Repairs - Address Cleaning"
  job_parameters = {
    "--TempDir"        = module.glue_temp_storage.bucket_url
    "--extra-py-files" = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
    "--source_catalog_database" : module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table" : "housing_repairs_repairs_dlo_cleaned"
    "--cleaned_addresses_s3_bucket_target" : "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses"
    "--source_address_column_header" : "property_address"
    "--source_postcode_column_header" : "postal_code_raw"
  }
  script_name            = aws_s3_bucket_object.address_cleaning.key
  workflow_name          = module.repairs_dlo[0].workflow_name
  triggered_by_crawler   = module.housing_repairs_dlo_cleaning_job[0].crawler_name
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  crawler_details = {
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses/"
  }
}

module "get_uprn_from_uhref_job" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department = module.department_housing_repairs
  job_name   = "${local.short_identifier_prefix}Get UPRN from UHref DLO repairs"
  job_parameters = {
    "--lookup_catalogue_table"      = "datainsight_data_and_insight"
    "--lookup_database"             = "dataplatform-stg-raw-zone-database"
    "--source_data_catalogue_table" = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--source_data_database"        = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_uhref_header"         = "property_reference_uh"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    "--TempDir"                     = module.glue_temp_storage.bucket_url
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  script_name            = aws_s3_bucket_object.get_uprn_from_uhref.key
  workflow_name          = module.repairs_dlo[0].workflow_name
  triggered_by_crawler   = module.housing_repairs_dlo_address_cleaning_job[0].crawler_name
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  crawler_details = {
    table_prefix       = "housing-repairs-with-uprn-from-uhref_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_cleaned_uhref_job_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-cleaned-uhref-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.department_housing_repairs.tags

  predicate {
    conditions {
      crawler_name = module.housing_repairs_dlo_address_cleaning_job[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_job.get_uprn_from_uhref[0].name
  }
}

resource "aws_glue_job" "get_uprn_from_uhref" {
  count = local.is_live_environment ? 1 : 0

  tags = module.department_housing_repairs.tags

  name              = "${local.short_identifier_prefix}Get UPRN from UHref DLO repairs"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.get_uprn_from_uhref.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--lookup_catalogue_table"      = "datainsight_data_and_insight"
    "--lookup_database"             = "dataplatform-stg-raw-zone-database"
    "--source_data_catalogue_table" = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--source_data_database"        = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_uhref_header"         = "property_reference_uh"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    "--TempDir"                     = module.glue_temp_storage.bucket_url
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_uprn_crawler_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-with-uprn-from-uhref-crawler"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.department_housing_repairs.tags

  predicate {
    conditions {
      job_name = aws_glue_job.get_uprn_from_uhref[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_with_uprn_from_uhref_crawler[0].name
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_with_uprn_from_uhref_crawler" {
  tags  = module.department_housing_repairs.tags
  count = local.is_live_environment ? 1 : 0

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-dlo-repairs-with-uprn-from-uhref"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing-repairs-with-uprn-from-uhref_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_trigger" "housing_repairs_dlo_address_matching_job_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-address-matching-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.department_housing_repairs.tags

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_with_uprn_from_uhref_crawler[0].name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_job.repairs_dlo_levenshtein_address_matching[0].name
  }
}

resource "aws_glue_job" "repairs_dlo_levenshtein_address_matching" {
  count = local.is_live_environment ? 1 : 0

  tags = module.department_housing_repairs.tags

  name              = "Housing Repairs - Repairs DLO Levenshtein Address Matching"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.levenshtein_address_matching.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--addresses_api_data_database" = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = "housing-repairs-refined-zone"
    "--source_catalog_table"        = "housing-repairs-with-uprn-from-uhref_with_uprn_from_uhref"
    "--match_to_property_shell"     = "forbid"
    "--target_destination"          = "s3://${module.trusted_zone.bucket_id}/housing-repairs/repairs/"
    "--TempDir"                     = module.glue_temp_storage.bucket_url
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}
