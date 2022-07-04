module "housing_repairs_axis" {
  count = local.is_live_environment ? 1 : 0

  source = "../modules/housing-repairs-google-sheets-cleaning"

  department                   = module.department_housing_repairs
  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  glue_scripts_bucket_id       = module.glue_scripts.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage.bucket_url
  refined_zone_bucket_id       = module.refined_zone.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  trusted_zone_bucket_id       = module.trusted_zone.bucket_id

  data_cleaning_script_name  = "repairs_axis_cleaning"
  source_catalog_table       = "housing_repairs_repairs_axis"
  trigger_crawler_name       = module.repairs_axis[0].crawler_name
  workflow_name              = module.repairs_axis[0].workflow_name
  dataset_name               = "repairs-axis"
  match_to_property_shell    = "allow"
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
}
