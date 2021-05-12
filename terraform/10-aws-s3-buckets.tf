module "landing_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Landing Zone"
  bucket_identifier              = "landing-zone"
  role_arns_to_share_access_with = [
    "arn:aws:iam::715003523189:root",
    aws_iam_role.rds_snapshot_to_s3_lambda.arn
  ]
}

module "raw_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Raw Zone"
  bucket_identifier              = "raw-zone"
}

module "refined_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Refined Zone"
  bucket_identifier              = "refined-zone"
}

module "trusted_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Trusted Zone"
  bucket_identifier              = "trusted-zone"
}

module "glue_scripts" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Glue Scripts"
  bucket_identifier              = "glue-scripts-1"
}

module "glue_temp_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Glue Temp Storage"
  bucket_identifier              = "glue-temp-storage-1"
}

module "athena_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Athena Storage"
  bucket_identifier              = "athena-storage-1"
}


/* ==== GLUE SCRIPTS ================================================================================================ */
resource "aws_kms_key" "glue_scripts_key" {
  tags = module.tags.values

  description             = "${var.project} ${var.environment} - Glue Scripts Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "glue_scripts_key_alias" {
  name = lower("alias/${local.identifier_prefix}-s3-glue-scripts")
  target_key_id = aws_kms_key.glue_scripts_key.key_id
}

resource "aws_s3_bucket" "glue_scripts_bucket" {
  tags = module.tags.values

  bucket        = lower("${local.identifier_prefix}-glue-scripts")
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 60
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.glue_scripts_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}