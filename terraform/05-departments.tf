data "aws_ssoadmin_instances" "sso_instances" {
  count = local.is_live_environment ? 1 : 0

  provider = aws.aws_hackit_account
}

locals {
  sso_instance_arn  = try(tolist(data.aws_ssoadmin_instances.sso_instances[0].arns)[0], "")
  identity_store_id = try(tolist(data.aws_ssoadmin_instances.sso_instances[0].identity_store_ids)[0], "")
}

module "department_housing_repairs" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Housing Repairs"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
}

module "department_parking" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Parking"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-parking@hackney.gov.uk"
}

module "department_finance" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Finance"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
}

module "department_data_and_insight" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Data and Insight"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-datainsight@hackney.gov.uk"
}

module "department_env_enforcement" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Env Enforcement"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
}

module "department_planning" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Planning"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-planning@hackney.gov.uk"
}

module "department_unrestricted" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Unrestricted"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
}

module "department_sandbox" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Sandbox"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-sandbox@hackney.gov.uk"
}

module "department_benefits_and_housing_needs" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Benefits and Housing Needs"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
//  google_group_display_name       = "saml-aws-data-platform-collaborator-benefits-housing-needs@hackney.gov.uk"
}

module "department_revenues" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Revenues"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
//  google_group_display_name       = "saml-aws-data-platform-collaborator-council-tax@hackney.gov.uk"
}

module "department_environmental_services" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                          = "../modules/department"
  tags                            = module.tags.values
  is_live_environment             = local.is_live_environment
  environment                     = var.environment
  application                     = local.application_snake
  short_identifier_prefix         = local.short_identifier_prefix
  identifier_prefix               = local.identifier_prefix
  name                            = "Environmental Services"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
//  google_group_display_name       = "saml-aws-data-platform-collaborator-environmental-services@hackney.gov.uk"
}
