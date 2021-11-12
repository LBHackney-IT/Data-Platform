resource "aws_s3_bucket_object" "housing_repairs_dlo_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/housing_repairs/repairs_dlo_cleaning.py"
  acl    = "private"
  source = "../scripts/jobs/housing_repairs/repairs_dlo_cleaning.py"
  etag   = filemd5("../scripts/jobs/housing_repairs/repairs_dlo_cleaning.py")
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
    "--TempDir"                          = "${module.glue_temp_storage.bucket_url}/${module.department_housing_repairs.identifier}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  script_name            = aws_s3_bucket_object.housing_repairs_dlo_cleaning_script.key
  workflow_name          = module.repairs_dlo[0].workflow_name
  triggered_by_crawler   = module.repairs_dlo[0].crawler_name
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  crawler_details = {
    table_prefix       = "housing_repairs_repairs_dlo_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned/"
  }
}

module "housing_repairs_dlo_address_cleaning_job" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department = module.department_housing_repairs
  job_name   = "${local.short_identifier_prefix}DLO Repairs - Address Cleaning"
  job_parameters = {
    "--TempDir"                            = "${module.glue_temp_storage.bucket_url}/${module.department_housing_repairs.identifier}/"
    "--extra-py-files"                     = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--source_catalog_database"            = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_repairs_dlo_cleaned"
    "--cleaned_addresses_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses"
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "postal_code_raw"
  }
  script_name            = aws_s3_bucket_object.address_cleaning.key
  workflow_name          = module.repairs_dlo[0].workflow_name
  triggered_by_crawler   = module.housing_repairs_dlo_cleaning_job[0].crawler_name
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  crawler_details = {
    table_prefix       = "housing_repairs_repairs_dlo_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses/"
  }
}

module "get_uprn_from_uhref_job" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department    = module.department_housing_repairs
  job_name      = "${local.short_identifier_prefix}Get UPRN from UHref DLO repairs"
  glue_role_arn = aws_iam_role.glue_role.arn
  job_parameters = {
    "--lookup_catalogue_table"      = "vulnerable_residents"
    "--lookup_database"             = module.department_data_and_insight.raw_zone_catalog_database_name
    "--source_data_catalogue_table" = "housing_repairs_repairs_dlo_with_cleaned_addresses"
    "--source_data_database"        = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_uhref_header"         = "property_reference_uh"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    "--TempDir"                     = "${module.glue_temp_storage.bucket_url}/${module.department_housing_repairs.identifier}/"
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  script_name            = aws_s3_bucket_object.get_uprn_from_uhref.key
  workflow_name          = module.repairs_dlo[0].workflow_name
  triggered_by_crawler   = module.housing_repairs_dlo_address_cleaning_job[0].crawler_name
  glue_scripts_bucket_id = module.glue_scripts.bucket_id
  crawler_details = {
    table_prefix       = "housing_repairs_repairs_dlo_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
  }
}

module "repairs_dlo_levenshtein_address_matching" {
  source = "../modules/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department = module.department_housing_repairs
  job_name   = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Levenshtein Address Matching"
  job_parameters = {
    "--addresses_api_data_database"      = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--addresses_api_data_table"         = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"          = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_dlo_with_uprn_from_uhref"
    "--match_to_property_shell"          = "forbid"
    "--target_destination"               = "s3://${module.trusted_zone.bucket_id}/housing-repairs/repairs/"
    "--TempDir"                          = "${module.glue_temp_storage.bucket_url}/${module.department_housing_repairs.identifier}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--enable-continuous-cloudwatch-log" = "true"
  }
  script_name                    = aws_s3_bucket_object.levenshtein_address_matching.key
  workflow_name                  = module.repairs_dlo[0].workflow_name
  triggered_by_crawler           = module.get_uprn_from_uhref_job[0].crawler_name
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 12
}
