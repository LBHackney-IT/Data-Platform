data "aws_secretsmanager_secret" "production_account_id" {
  name = "manually-managed-value-prod-account-id"
}

data "aws_secretsmanager_secret_version" "production_account_id" {
  secret_id = data.aws_secretsmanager_secret.production_account_id.id
}

locals {
  rentsense_refined_zone_access_statement = {
    sid    = "AllowRentsenseReadOnlyAccessToExportLocationOnRefinedZone"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging"
    ]

    resources = [
      module.refined_zone.bucket_arn,
      "${module.refined_zone.bucket_arn}/housing/rentsense/export/*"
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
    sid    = "RentSenseAccesToRefinedZoneKey"
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

  s3_to_s3_copier_for_addresses_api_write_access_to_raw_zone_statement = {
    sid    = "AllowS3toS3CopierForAddressesAPIWriteAccessToRawZoneUnrestrictedAddressesAPILocation"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      module.raw_zone.bucket_arn,
      "${module.raw_zone.bucket_arn}/unrestricted/addresses_api/*"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_api_account_id}:root",
        "arn:aws:iam::${var.aws_api_account_id}:role/${lower(local.identifier_prefix)}-s3-to-s3-copier-lambda"
      ]
    }
  }

  s3_to_s3_copier_for_addresses_api_raw_zone_key_statement = {
    sid    = "S3ToS3CopierForAddressesAPIAccessToRawZoneKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.aws_api_account_id}:root",
        "arn:aws:iam::${var.aws_api_account_id}:role/${lower(local.identifier_prefix)}-s3-to-s3-copier-lambda"
      ]
    }
  }

  prod_to_pre_prod_trusted_zone_data_sync_statement_for_pre_prod = {
    sid    = "ProdToPreProdTrustedZoneDataSyncAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject*",
      "s3:DeleteObject*",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete"
    ]

    resources = [
      "arn:aws:s3:::dataplatform-stg-trusted-zone",
      "arn:aws:s3:::dataplatform-stg-trusted-zone/*"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/production-to-pre-production-s3-sync-role"
      ]
    }
  }

  prod_to_pre_prod_data_sync_access_to_trusted_zone_key_statement_for_pre_prod = {
    sid    = "ProdToPreProdTrustedZoneDataSyncKeyAccess"
    effect = "Allow"
    actions = [
      "kms:RetireGrant",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/production-to-pre-production-s3-sync-role"
      ]
    }
  }

  prod_to_pre_prod_refined_zone_data_sync_statement_for_pre_prod = {
    sid    = "ProdToPreProdRefinedZoneDataSyncAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject*",
      "s3:DeleteObject*",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete"
    ]

    resources = [
      "arn:aws:s3:::dataplatform-stg-refined-zone",
      "arn:aws:s3:::dataplatform-stg-refined-zone/*"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/production-to-pre-production-s3-sync-role"
      ]
    }
  }

  prod_to_pre_prod_data_sync_access_to_refined_zone_key_statement_for_pre_prod = {
    sid    = "ProdToPreProdRefinedZoneDataSyncKeyAccess"
    effect = "Allow"
    actions = [
      "kms:RetireGrant",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/production-to-pre-production-s3-sync-role"
      ]
    }
  }

  prod_to_pre_prod_raw_zone_data_sync_statement_for_pre_prod = {
    sid    = "ProdToPreProdRawZoneDataSyncAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject*",
      "s3:DeleteObject*",
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete"
    ]

    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone",
      "arn:aws:s3:::dataplatform-stg-raw-zone/*"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/production-to-pre-production-s3-sync-role"
      ]
    }
  }

  prod_to_pre_prod_data_sync_access_to_raw_zone_key_statement_for_pre_prod = {
    sid    = "ProdToPreProdRawZoneDataSyncKeyAccess"
    effect = "Allow"
    actions = [
      "kms:RetireGrant",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:CreateGrant"
    ]

    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_secretsmanager_secret_version.production_account_id.secret_string}:role/production-to-pre-production-s3-sync-role"
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
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Raw Zone"
  bucket_identifier              = "raw-zone"
  role_arns_to_share_access_with = [var.sync_production_to_pre_production_task_role]
  bucket_policy_statements       = local.is_production_environment ? [local.s3_to_s3_copier_for_addresses_api_write_access_to_raw_zone_statement] : [local.prod_to_pre_prod_raw_zone_data_sync_statement_for_pre_prod]
  bucket_key_policy_statements   = local.is_production_environment ? [local.s3_to_s3_copier_for_addresses_api_raw_zone_key_statement] : [local.prod_to_pre_prod_data_sync_access_to_raw_zone_key_statement_for_pre_prod]

}

module "refined_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Refined Zone"
  bucket_identifier              = "refined-zone"
  role_arns_to_share_access_with = [var.sync_production_to_pre_production_task_role]

  bucket_policy_statements = concat(
    [local.rentsense_refined_zone_access_statement],
  local.is_live_environment && local.is_production_environment ? [] : [local.prod_to_pre_prod_refined_zone_data_sync_statement_for_pre_prod])

  bucket_key_policy_statements = concat(
    [local.rentsense_refined_zone_key_statement],
  local.is_live_environment && local.is_production_environment ? [] : [local.prod_to_pre_prod_data_sync_access_to_refined_zone_key_statement_for_pre_prod])
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

  bucket_policy_statements     = local.is_live_environment && local.is_production_environment ? [] : [local.prod_to_pre_prod_trusted_zone_data_sync_statement_for_pre_prod]
  bucket_key_policy_statements = local.is_live_environment && local.is_production_environment ? [] : [local.prod_to_pre_prod_data_sync_access_to_trusted_zone_key_statement_for_pre_prod]
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