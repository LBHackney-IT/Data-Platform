locals {
  rentsense_refined_zone_access_statement = {
    sid = "AllowRentsenseReadOnlyAccessToExportLocationOnRefinedZone"
    effect = "Allow"
    actions = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:GetObjectTagging"
    ]
  
    resources = [
        "${module.refined_zone.bucket_arn}",
        "${module.refined_zone.bucket_arn}/housings/rentsense/export/*"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::971933469343:root",
        "arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104"
      ]
    }
  }
    
  rentsense_refined_zone_key_statement = {
    sid = "RentSenseAccesToRefinedZoneKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::971933469343:root",
        "arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104"
      ]
    }
  }
}

module "landing_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Landing Zone"
  bucket_identifier = "landing-zone"
}

module "raw_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Raw Zone"
  bucket_identifier = "raw-zone"

  role_arns_to_share_access_with = concat(
    local.is_production_environment ? [module.db_snapshot_to_s3[0].s3_to_s3_copier_lambda_role_arn] : [],
  [var.sync_production_to_pre_production_task_role])
}

module "refined_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Refined Zone"
  bucket_identifier = "refined-zone"
  role_arns_to_share_access_with  = [var.sync_production_to_pre_production_task_role]
  bucket_policy_statements        = [local.rentsense_refined_zone_access_statement]
  bucket_key_policy_statements    = [local.rentsense_refined_zone_key_statement]
}

module "trusted_zone" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Trusted Zone"
  bucket_identifier = "trusted-zone"
  role_arns_to_share_access_with = [
    var.sync_production_to_pre_production_task_role
  ]
}

module "glue_scripts" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Glue Scripts"
  bucket_identifier = "glue-scripts"
}

module "glue_temp_storage" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Glue Temp Storage"
  bucket_identifier = "glue-temp-storage"
}

module "athena_storage" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Athena Storage"
  bucket_identifier = "athena-storage"
}

module "lambda_artefact_storage" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Lambda Artefact Storage"
  bucket_identifier = "dp-lambda-artefact-storage"
}

module "spark_ui_output_storage" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Spark UI Storage"
  bucket_identifier = "spark-ui-output-storage"
}

# This bucket is used for storing certificates used in Looker Studio connections.
# The generated certificate/private key isn't special/used for auth.
resource "aws_s3_bucket" "ssl_connection_resources" {
  count = local.is_live_environment ? 1 : 0

  bucket = "${local.identifier_prefix}-ssl-connection-resources"
  tags   = module.tags.values

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_acl" "ssl_connection_resources" {
  count = local.is_live_environment ? 1 : 0

  bucket = aws_s3_bucket.ssl_connection_resources[0].id
  acl    = "private"
}