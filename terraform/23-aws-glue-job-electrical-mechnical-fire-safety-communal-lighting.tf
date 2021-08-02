resource "aws_s3_bucket_object" "housing_repairs_elec_mech_fire_communal_lighting_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/elec_mech_fire_communal_lighting.py"
  acl    = "private"
  source = "../scripts/elec_mech_fire_communal_lighting.py"
  etag   = filemd5("../scripts/elec_mech_fire_communal_lighting.py")
}

module "communal_lighting" {
  count = local.is_live_environment ? 1 : 0

  source = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  tags   = module.tags.values

  short_identifier_prefix            = local.short_identifier_prefix
  identifier_prefix                  = local.identifier_prefix
  department_name                    = "housing-repairs"
  script_key                         = aws_s3_bucket_object.housing_repairs_elec_mech_fire_communal_lighting_script.key
  glue_scripts_bucket_id             = module.glue_scripts.bucket_id
  glue_role_arn                      = aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs        = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_id        = module.glue_temp_storage.bucket_url
  refined_zone_bucket_id             = module.refined_zone.bucket_id
  helper_script_key                  = aws_s3_bucket_object.helpers.key
  cleaning_helper_script_key         = aws_s3_bucket_object.repairs_cleaning_helpers.key
  catalog_database                   = module.department_housing_repairs.raw_zone_catalog_database_name
  worksheet_resource                 = module.repairs_fire_alarm_aov[0].worksheet_resources["communal-lighting"]
  refined_zone_catalog_database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  dataset_name                       = "communal-lighting"
  address_cleaning_script_key        = aws_s3_bucket_object.address_cleaning.key
}
