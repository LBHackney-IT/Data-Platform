resource "aws_s3_bucket_object" "housing_repairs_repairs_avonline_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_avonline_cleaning.py"
  acl    = "private"
  source = "../scripts/repairs_avonline_cleaning.py"
  etag   = filemd5("../scripts/repairs_avonline_cleaning.py")
}

module "housing_repairs_avonline" {
  count = local.is_live_environment ? 1 : 0

  source = "../modules/housing-repairs-google-sheets-cleaning"
  tags   = module.tags.values

  short_identifier_prefix            = local.short_identifier_prefix
  identifier_prefix                  = local.identifier_prefix
  department_name                    = "housing-repairs"
  glue_scripts_bucket_id             = module.glue_scripts.bucket_id
  glue_role_arn                      = aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs        = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_id        = module.glue_temp_storage.bucket_url
  refined_zone_bucket_id             = module.refined_zone.bucket_id
  helper_script_key                  = aws_s3_bucket_object.helpers.key
  cleaning_helper_script_key         = aws_s3_bucket_object.repairs_cleaning_helpers.key
  catalog_database                   = module.department_housing_repairs.raw_zone_catalog_database_name
  refined_zone_catalog_database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  address_cleaning_script_key        = aws_s3_bucket_object.address_cleaning.key

  data_cleaning_script_key = aws_s3_bucket_object.housing_repairs_repairs_avonline_cleaning_script.key
  source_catalog_table     = "housing_repairs_repairs_avonline"
  trigger_crawler_name     = module.repairs_avonline[0].crawler_name
  workflow_name            = module.repairs_avonline[0].workflow_name
  dataset_name             = "repairs-avonline"
}
