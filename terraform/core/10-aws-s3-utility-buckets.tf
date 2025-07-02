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
