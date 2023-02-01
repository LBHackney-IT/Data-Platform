module "department_housing_repairs_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Housing Repairs"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_parking_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Parking"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_finance_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Finance"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_data_and_insight_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Data and Insight"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_env_enforcement_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Env Enforcement"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_planning_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Planning"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_unrestricted_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Unrestricted"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_sandbox_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Sandbox"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_benefits_and_housing_needs_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Bens Housing Needs"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_revenues_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Revenues"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_environmental_services_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Env Services"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_housing_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Housing"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}

module "department_customer_services_data_source" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../modules/data-sources/department"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Customer Services"
  glue_scripts_bucket      = module.glue_scripts_data_source
  glue_temp_storage_bucket = module.glue_temp_storage_data_source
}