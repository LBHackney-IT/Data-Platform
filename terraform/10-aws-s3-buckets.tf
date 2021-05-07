module "landing_zone" {
  source                = "../modules/s3-bucket"
  tags                  = module.tags.values
  project               = var.project
  environment           = var.environment
  identifier_prefix     = local.identifier_prefix
  account_configuration = local.departments
  bucket_name           = "Landing Zone"
  bucket_identifier     = "landing-zone"

  depends_on = [aws_iam_role.rds_snapshot_export_service]
}

module "raw_zone" {
  source                = "../modules/s3-bucket"
  tags                  = module.tags.values
  project               = var.project
  environment           = var.environment
  identifier_prefix     = local.identifier_prefix
  account_configuration = local.departments
  bucket_name           = "Raw Zone"
  bucket_identifier     = "raw-zone"
}

module "refined_zone" {
  source                = "../modules/s3-bucket"
  tags                  = module.tags.values
  project               = var.project
  environment           = var.environment
  identifier_prefix     = local.identifier_prefix
  account_configuration = local.departments
  bucket_name           = "Refined Zone"
  bucket_identifier     = "refined-zone"
}

module "trusted_zone" {
  source                = "../modules/s3-bucket"
  tags                  = module.tags.values
  project               = var.project
  environment           = var.environment
  identifier_prefix     = local.identifier_prefix
  account_configuration = local.departments
  bucket_name           = "Trusted Zone"
  bucket_identifier     = "trusted-zone"
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

/* ==== GLUE TEMP STORAGE =========================================================================================== */
resource "aws_kms_key" "glue_temp_storage_bucket_key" {
  tags = module.tags.values

  description             = "${var.project} ${var.environment} - Glue Temp Storage Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "glue_temp_storage_bucket" {
  tags = module.tags.values

  bucket        = lower("${local.identifier_prefix}-glue-temp-storage")
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.glue_temp_storage_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

/* ==== ATHENA STORAGE ============================================================================================== */
resource "aws_kms_key" "athena_storage_bucket_key" {
  tags = module.tags.values

  description             = "${var.project} ${var.environment} - Glue Temp Storage Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "athena_storage_bucket" {
  tags = module.tags.values

  bucket        = lower("${local.identifier_prefix}-athena-storage")
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.athena_storage_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
