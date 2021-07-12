module "department_housing_repairs" {
  source                   = "../modules/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  application              = local.application_snake
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Housing Repairs"
  landing_zone_bucket      = module.landing_zone
  raw_zone_bucket          = module.raw_zone
  refined_zone_bucket      = module.refined_zone
  trusted_zone_bucket      = module.trusted_zone
  athena_storage_bucket    = module.athena_storage
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
  secrets_manager_kms_key  = aws_kms_key.secrets_manager_key
}

module "department_parking" {
  source                   = "../modules/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  application              = local.application_snake
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Parking"
  landing_zone_bucket      = module.landing_zone
  raw_zone_bucket          = module.raw_zone
  refined_zone_bucket      = module.refined_zone
  trusted_zone_bucket      = module.trusted_zone
  athena_storage_bucket    = module.athena_storage
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
  secrets_manager_kms_key  = aws_kms_key.secrets_manager_key
}

module "department_finance" {
  source                   = "../modules/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  application              = local.application_snake
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Finance"
  landing_zone_bucket      = module.landing_zone
  raw_zone_bucket          = module.raw_zone
  refined_zone_bucket      = module.refined_zone
  trusted_zone_bucket      = module.trusted_zone
  athena_storage_bucket    = module.athena_storage
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
  secrets_manager_kms_key  = aws_kms_key.secrets_manager_key
}

module "department_data_and_insight" {
  source                   = "../modules/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  application              = local.application_snake
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Data and Insight"
  landing_zone_bucket      = module.landing_zone
  raw_zone_bucket          = module.raw_zone
  refined_zone_bucket      = module.refined_zone
  trusted_zone_bucket      = module.trusted_zone
  athena_storage_bucket    = module.athena_storage
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
  secrets_manager_kms_key  = aws_kms_key.secrets_manager_key
}