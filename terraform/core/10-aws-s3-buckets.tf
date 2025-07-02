#===============================================================================
# Data Sources
#===============================================================================

data "aws_secretsmanager_secret" "production_account_id" {
  name = "manually-managed-value-prod-account-id"
}

data "aws_secretsmanager_secret_version" "production_account_id" {
  secret_id = data.aws_secretsmanager_secret.production_account_id.id
}

data "aws_secretsmanager_secret" "housing_production_account_id" {
  name = "manually-managed-value-housing-prod-account-id"
}

data "aws_secretsmanager_secret_version" "housing_production_account_id" {
  secret_id = data.aws_secretsmanager_secret.housing_production_account_id.id
}

#===============================================================================
# Data Zone Buckets
#===============================================================================

module "landing_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Landing Zone"
  bucket_identifier = "landing-zone"

  bucket_policy_statements = concat(
    local.is_prod_env ? [
      local.allow_housing_reporting_role_access_to_landing_zone_path
    ] : [],
    local.is_preprod_env ? [
      local.allow_housing_reporting_role_access_to_landing_zone_path_pre_prod,
      local.allow_access_from_academy_account
    ] : []
  )
  bucket_key_policy_statements = [
    local.share_kms_key_with_housing_reporting_role,
    local.share_kms_key_with_academy_account
  ]
  include_backup_policy_tags = false
}

module "raw_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Raw Zone"
  bucket_identifier = "raw-zone"

  bucket_policy_statements = concat(
    local.is_prod_env ? [
      local.s3_to_s3_copier_for_addresses_api_write_access_to_raw_zone_statement
    ] : [],
    local.is_preprod_env ? [
      local.prod_to_pre_prod_raw_zone_data_sync_statement_for_pre_prod
    ] : []
  )
  bucket_key_policy_statements = concat(
    local.is_prod_env ? [
      local.s3_to_s3_copier_for_addresses_api_raw_zone_key_statement
    ] : [],
    local.is_preprod_env ? [
      local.prod_to_pre_prod_data_sync_access_to_raw_zone_key_statement_for_pre_prod
    ] : [],
    [local.allow_s3_access_to_raw_zone_kms_key]
  )
  include_backup_policy_tags = false
}

module "refined_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Refined Zone"
  bucket_identifier = "refined-zone"

  bucket_policy_statements = concat(
    [local.rentsense_refined_zone_access_statement],
    local.is_preprod_env ? [
      local.prod_to_pre_prod_refined_zone_data_sync_statement_for_pre_prod
    ] : []
  )

  bucket_key_policy_statements = concat(
    [local.rentsense_refined_zone_key_statement],
    local.is_preprod_env ? [
      local.prod_to_pre_prod_data_sync_access_to_refined_zone_key_statement_for_pre_prod
    ] : [],
    [local.allow_s3_access_to_refined_zone_kms_key]
  )
  include_backup_policy_tags = false
}

module "trusted_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Trusted Zone"
  bucket_identifier = "trusted-zone"

  bucket_policy_statements = local.is_preprod_env ? [
    local.prod_to_pre_prod_trusted_zone_data_sync_statement_for_pre_prod
  ] : []

  bucket_key_policy_statements = concat(
    local.is_preprod_env ? [
      local.prod_to_pre_prod_data_sync_access_to_trusted_zone_key_statement_for_pre_prod
    ] : [],
    [local.allow_s3_access_to_trusted_zone_kms_key]
  )
  include_backup_policy_tags = false
}

#===============================================================================
# Processing and Utility Buckets
#===============================================================================

module "glue_scripts" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Glue Scripts"
  bucket_identifier          = "glue-scripts"
  include_backup_policy_tags = false
}

module "glue_temp_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Glue Temp Storage"
  bucket_identifier          = "glue-temp-storage"
  include_backup_policy_tags = false
}

module "athena_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Athena Storage"
  bucket_identifier          = "athena-storage"
  include_backup_policy_tags = false
}

module "spark_ui_output_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Spark UI Storage"
  bucket_identifier              = "spark-ui-output-storage"
  versioning_enabled             = false
  expire_objects_days            = 60
  expire_noncurrent_objects_days = 30
  abort_multipart_days           = 30
  include_backup_policy_tags     = false
}

#===============================================================================
# Application and Storage Buckets
#===============================================================================

module "lambda_artefact_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Lambda Artefact Storage"
  bucket_identifier          = "dp-lambda-artefact-storage"
  versioning_enabled         = false
  include_backup_policy_tags = false
}

module "rds_export_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "RDS Export Storage"
  bucket_identifier          = "rds-shapshot-export-storage"
  include_backup_policy_tags = false
}

module "deprecated_rds_export_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = "${local.identifier_prefix}-dp"
  bucket_name                = "RDS Export Storage"
  bucket_identifier          = "rds-export-storage"
  include_backup_policy_tags = false
}

module "addresses_api_rds_export_storage" {
  source = "../modules/s3-bucket"

  tags                           = merge(module.tags.values, { "Team" = "DataAndInsight" })
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "RDS Export Storage"
  bucket_identifier              = "rds-export-storage"
  role_arns_to_share_access_with = local.is_prod_env ? [module.db_snapshot_to_s3[0].rds_snapshot_to_s3_lambda_role_arn] : []

  providers = {
    aws = aws.aws_api_account
  }
  include_backup_policy_tags = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "addresses_api_rds_export_storage" {
  bucket = module.addresses_api_rds_export_storage.bucket_id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.addresses_api_rds_export_storage.kms_key_arn
    }
    bucket_key_enabled = true
  }

  provider = aws.aws_api_account
}

#===============================================================================
# Special Purpose Buckets
#===============================================================================

# This bucket is used for storing certificates used in Looker Studio connections.
# The generated certificate/private key isn't special/used for auth.
resource "aws_s3_bucket" "ssl_connection_resources" {
  count = local.is_live_environment ? 1 : 0

  bucket = "${local.identifier_prefix}-ssl-connection-resources"
  tags = {
    for key, value in module.tags.values :
    key => value if key != "BackupPolicy"
  }
}

resource "aws_s3_bucket_acl" "ssl_connection_resources" {
  count = local.is_live_environment ? 1 : 0

  bucket = aws_s3_bucket.ssl_connection_resources[0].id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "ssl_connection_resources" {
  count = local.is_live_environment ? 1 : 0

  bucket = aws_s3_bucket.ssl_connection_resources[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

module "housing_nec_migration_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Housing NEC Migration Storage"
  bucket_identifier          = "housing-nec-migration-storage"
  include_backup_policy_tags = false
}

module "admin_bucket" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Admin Storage"
  bucket_identifier          = "admin"
  bucket_policy_statements   = [local.grant_s3_write_permission_to_admin_bucket]
  include_backup_policy_tags = false
}
