module "department_housing_repairs" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Housing Repairs"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_parking" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Parking"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_finance" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Finance"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_data_and_insight" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Data and Insight"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_env_enforcement" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Env Enforcement"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_planning" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Planning"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_unrestricted" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Unrestricted"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_sandbox" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Sandbox"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_benefits_and_housing_needs" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Bens Housing Needs"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_revenues" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Revenues"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_environmental_services" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Env Services"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}

module "department_housing" {
  providers = {
    aws                    = aws
    aws.aws_hackit_account = aws.aws_hackit_account
  }

  source                   = "../../modules/data-sources/department-data-source"
  tags                     = module.tags.values
  is_live_environment      = local.is_live_environment
  environment              = var.environment
  short_identifier_prefix  = local.short_identifier_prefix
  identifier_prefix        = local.identifier_prefix
  name                     = "Housing"
  glue_scripts_bucket      = module.glue_scripts
  glue_temp_storage_bucket = module.glue_temp_storage
}
