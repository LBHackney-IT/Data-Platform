module "tascomi" {
  source                         = "../modules/tascomi-api-ingestor"
  tags                           = module.tags.values
  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  zone_kms_key_arn               = module.landing_zone.kms_key_arn
  zone_bucket_arn                = module.landing_zone.bucket_arn
  zone_bucket_id                 = module.landing_zone.bucket_id
  resource_name                  = "users"
  service_area                   = "housing"
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_catalog_database_name     = module.department_housing_repairs.landing_zone_catalog_database_name
  helpers_script_key             = aws_s3_bucket_object.helpers.key
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  tascomi_public_key             = var.tascomi_public_key
  tascomi_private_key            = var.tascomi_private_key
}
