resource "aws_s3_bucket_object" "housing_repairs_dlo_cleaning_script" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/housing_repairs/repairs_dlo_cleaning.py"
  acl         = "private"
  source      = "../../scripts/jobs/housing_repairs/repairs_dlo_cleaning.py"
  source_hash = filemd5("../../scripts/jobs/housing_repairs/repairs_dlo_cleaning.py")
}

module "housing_repairs_dlo_cleaning_job" {
  source = "../modules/resources/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department        = module.department_housing_repairs
  job_name          = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Cleaning"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_dlo"
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned"
  }
  script_s3_object_key       = aws_s3_bucket_object.housing_repairs_dlo_cleaning_script.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  workflow_name              = module.repairs_dlo[0].workflow_name
  triggered_by_crawler       = module.repairs_dlo[0].crawler_name
  crawler_details = {
    table_prefix       = "housing_repairs_repairs_dlo_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned/"
  }
}

module "housing_repairs_dlo_address_cleaning_job" {
  source = "../modules/resources/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department        = module.department_housing_repairs
  job_name          = "${local.short_identifier_prefix}DLO Repairs - Address Cleaning"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--source_catalog_database"            = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table"               = "housing_repairs_repairs_dlo_cleaned"
    "--cleaned_addresses_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses"
    "--source_address_column_header"       = "property_address"
    "--source_postcode_column_header"      = "postal_code_raw"
  }
  script_s3_object_key       = aws_s3_bucket_object.address_cleaning.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  workflow_name              = module.repairs_dlo[0].workflow_name
  triggered_by_crawler       = module.housing_repairs_dlo_cleaning_job[0].crawler_name
  crawler_details = {
    table_prefix       = "housing_repairs_repairs_dlo_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses/"
  }
}

module "get_uprn_from_uhref_job" {
  source = "../modules/resources/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department        = module.department_housing_repairs
  job_name          = "${local.short_identifier_prefix}Get UPRN from UHref DLO repairs"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  glue_role_arn     = aws_iam_role.glue_role.arn
  job_parameters = {
    "--lookup_catalogue_table"      = "vulnerable_residents"
    "--lookup_database"             = module.department_data_and_insight.raw_zone_catalog_database_name
    "--source_data_catalogue_table" = "housing_repairs_repairs_dlo_with_cleaned_addresses"
    "--source_data_database"        = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_uhref_header"         = "property_reference_uh"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
  }
  script_s3_object_key       = aws_s3_bucket_object.get_uprn_from_uhref.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  workflow_name              = module.repairs_dlo[0].workflow_name
  triggered_by_crawler       = module.housing_repairs_dlo_address_cleaning_job[0].crawler_name
  crawler_details = {
    table_prefix       = "housing_repairs_repairs_dlo_"
    database_name      = module.department_housing_repairs.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
  }
}

module "repairs_dlo_levenshtein_address_matching" {
  source = "../modules/resources/aws-glue-job"
  count  = local.is_live_environment ? 1 : 0

  department        = module.department_housing_repairs
  job_name          = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Levenshtein Address Matching"
  helper_module_key = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  job_parameters = {
    "--addresses_api_data_database" = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table"        = "housing_repairs_repairs_dlo_with_uprn_from_uhref"
    "--match_to_property_shell"     = "forbid"
    "--target_destination"          = "s3://${module.trusted_zone.bucket_arn}/housing-repairs/repairs/"
  }
  script_s3_object_key           = aws_s3_bucket_object.levenshtein_address_matching.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  workflow_name                  = module.repairs_dlo[0].workflow_name
  triggered_by_crawler           = module.get_uprn_from_uhref_job[0].crawler_name
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 12
}
