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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-parking@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
  additional_glue_database_access = [
    {
      database_name = "${local.identifier_prefix}-liberator*"
      access_level  = "read_only"
    },
  ]
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-datainsight@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
  cloudtrail_bucket               = module.cloudtrail_storage
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-planning@hackney.gov.uk"
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
  additional_glue_database_access = [
    {
      database_name = "${local.identifier_prefix}-tascomi*"
      access_level  = "read_only"
    },
  ]
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-sandbox@hackney.gov.uk"
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  name                            = "Bens Housing Needs"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-benefits-housing-needs@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-revenues@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
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
  name                            = "Env Services"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-environmental-services@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
}

module "department_housing" {
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
  name                            = "Housing"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-housing@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
  additional_s3_access = [
    {
      bucket_arn  = module.housing_nec_migration_storage.bucket_arn
      kms_key_arn = module.housing_nec_migration_storage.kms_key_arn
      paths       = []
      actions     = ["s3:Get*", "s3:List*", "s3:Put*", "s3:Delete*"]
    },
    {
      bucket_arn  = module.file_sync_destination_nec.bucket_arn
      kms_key_arn = module.file_sync_destination_nec.key_arn
      paths       = []
      actions     = ["s3:Get*", "s3:List*", "s3:Put*", "s3:Delete*"]
    }
  ]
  additional_glue_database_access = [
    {
      database_name = "housing_nec_migration"
      access_level  = "read_write"
    },
    {
      database_name = "housing_nec_migration_outputs"
      access_level  = "read_write"
    }
  ]
}

module "department_children_and_education" {
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
  name                            = "Children and Edu"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-children-and-family-services@hackney.gov.uk"
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
}

module "department_customer_services" {
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
  name                            = "Customer Services"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-customer-services@hackney.gov.uk"
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
}

module "department_hr_and_od" {
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
  name                            = "HR and OD"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-hr-and-od@hackney.gov.uk"
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
}

module "department_streetscene" {
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
  name                            = "Streetscene"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-streetscene@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
}

module "department_children_family_services" {
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
  name                            = "Child Fam Services"
  landing_zone_bucket             = module.landing_zone
  raw_zone_bucket                 = module.raw_zone
  refined_zone_bucket             = module.refined_zone
  trusted_zone_bucket             = module.trusted_zone
  athena_storage_bucket           = module.athena_storage
  glue_scripts_bucket             = module.glue_scripts
  glue_temp_storage_bucket        = module.glue_temp_storage
  spark_ui_output_storage_bucket  = module.spark_ui_output_storage
  secrets_manager_kms_key         = aws_kms_key.secrets_manager_key
  redshift_ip_addresses           = var.redshift_public_ips
  redshift_port                   = var.redshift_port
  sso_instance_arn                = local.sso_instance_arn
  identity_store_id               = local.identity_store_id
  google_group_admin_display_name = local.google_group_admin_display_name
  google_group_display_name       = "saml-aws-data-platform-collaborator-cfs@hackney.gov.uk"
  departmental_airflow_user       = true
  mwaa_etl_scripts_bucket_arn     = aws_s3_bucket.mwaa_etl_scripts_bucket.arn
  mwaa_key_arn                    = aws_kms_key.mwaa_key.arn
}
