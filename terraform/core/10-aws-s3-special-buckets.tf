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
  bucket_key_policy_statements = [
    local.allow_s3_kms_generatedatakey_from_raw_zone,
    local.allow_s3_kms_generatedatakey_from_refined_zone,
    local.allow_s3_kms_generatedatakey_from_trusted_zone
    ]
  include_backup_policy_tags = false
}
