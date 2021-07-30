data "aws_ssoadmin_instances" "sso_instances" {
  provider = aws.aws_hackit_account
}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.sso_instances.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso_instances.identity_store_ids)[0]
}

module "department_housing_repairs" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

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
  sso_instance_arn         = local.sso_instance_arn
  identity_store_id        = local.identity_store_id
}

module "department_parking" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

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
  sso_instance_arn         = local.sso_instance_arn
  identity_store_id        = local.identity_store_id
}

module "department_finance" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

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
  sso_instance_arn         = local.sso_instance_arn
  identity_store_id        = local.identity_store_id
}

module "department_data_and_insight" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

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
  sso_instance_arn         = local.sso_instance_arn
  identity_store_id        = local.identity_store_id
}