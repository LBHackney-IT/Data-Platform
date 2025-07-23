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
# CloudTrail Storage Bucket
#===============================================================================

module "cloudtrail_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "CloudTrail" # Used in kms key description
  bucket_identifier              = "cloudtrail" # Used in created bucket name and kms key alias
  versioning_enabled             = true
  expire_objects_days            = 365
  expire_noncurrent_objects_days = 30
  abort_multipart_days           = 30
  include_backup_policy_tags     = false

  # CloudTrail-specific bucket policy statements (only in production)
  bucket_policy_statements = local.is_production_environment ? [
    local.cloudtrail_get_bucket_acl_statement,
    local.cloudtrail_put_object_statement
  ] : []
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
  role_arns_to_share_access_with = local.is_production_environment ? [module.db_snapshot_to_s3[0].rds_snapshot_to_s3_lambda_role_arn] : []

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
# MWAA Buckets
#===============================================================================

# Create the S3 bucket using the KMS key
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "${local.identifier_prefix}-mwaa-bucket"

  tags = {
    for key, value in module.tags.values :
    key => value if key != "BackupPolicy"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_bucket_encryption" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.mwaa_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "mwaa_bucket_block" {
  bucket = aws_s3_bucket.mwaa_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "mwaa_etl_scripts_bucket" {
  bucket = "${local.identifier_prefix}-mwaa-etl-scripts-bucket"
  tags = {
    for key, value in module.tags.values :
    key => value if key != "BackupPolicy"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mwaa_etl_scripts_bucket_encryption" {
  bucket = aws_s3_bucket.mwaa_etl_scripts_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.mwaa_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "mwaa_etl_scripts_bucket_block" {
  bucket = aws_s3_bucket.mwaa_etl_scripts_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
