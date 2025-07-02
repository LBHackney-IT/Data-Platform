#===============================================================================
# S3 Bucket Policy Statements
#===============================================================================

locals {
  is_preprod_env = local.is_live_environment && !local.is_production_environment

  prod_account_id    = data.aws_secretsmanager_secret_version.production_account_id.secret_string
  housing_account_id = data.aws_secretsmanager_secret_version.housing_production_account_id.secret_string

  #-----------------------------------------------------------------------------
  # RentSense Access Policies
  #-----------------------------------------------------------------------------

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
      "${module.refined_zone.bucket_arn}/housing/rentsense/export/*",
      "${module.refined_zone.bucket_arn}/housing/rentsense-ft/export/*"
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
    sid     = "RentSenseAccesToRefinedZoneKey"
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    principals = {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::971933469343:root",
        "arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104"
      ]
    }
  }

  #-----------------------------------------------------------------------------
  # S3-to-S3 Copier Policies (Addresses API)
  #-----------------------------------------------------------------------------

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

  #-----------------------------------------------------------------------------
  # Production-to-Preproduction Sync Policies
  #-----------------------------------------------------------------------------

  prod_to_preprod_sync_role_arn = "arn:aws:iam::${local.prod_account_id}:role/production-to-pre-production-s3-sync-role"

  prod_to_preprod_kms_actions = [
    "kms:RetireGrant",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:Encrypt",
    "kms:DescribeKey",
    "kms:Decrypt",
    "kms:CreateGrant"
  ]

  prod_to_preprod_s3_actions = [
    "s3:ListBucket",
    "s3:PutObject*",
    "s3:DeleteObject*",
    "s3:ReplicateObject",
    "s3:ReplicateTags",
    "s3:ObjectOwnerOverrideToBucketOwner",
    "s3:ReplicateDelete"
  ]

  prod_to_pre_prod_raw_zone_data_sync_statement_for_pre_prod = {
    sid     = "ProdToPreProdRawZoneDataSyncAccess"
    effect  = "Allow"
    actions = local.prod_to_preprod_s3_actions
    resources = [
      "arn:aws:s3:::dataplatform-stg-raw-zone",
      "arn:aws:s3:::dataplatform-stg-raw-zone/*"
    ]
    principals = {
      type        = "AWS"
      identifiers = [local.prod_to_preprod_sync_role_arn]
    }
  }

  prod_to_pre_prod_data_sync_access_to_raw_zone_key_statement_for_pre_prod = {
    sid     = "ProdToPreProdRawZoneDataSyncKeyAccess"
    effect  = "Allow"
    actions = local.prod_to_preprod_kms_actions
    principals = {
      type        = "AWS"
      identifiers = [local.prod_to_preprod_sync_role_arn]
    }
  }

  prod_to_pre_prod_refined_zone_data_sync_statement_for_pre_prod = {
    sid     = "ProdToPreProdRefinedZoneDataSyncAccess"
    effect  = "Allow"
    actions = local.prod_to_preprod_s3_actions
    resources = [
      "arn:aws:s3:::dataplatform-stg-refined-zone",
      "arn:aws:s3:::dataplatform-stg-refined-zone/*"
    ]
    principals = {
      type        = "AWS"
      identifiers = [local.prod_to_preprod_sync_role_arn]
    }
  }

  prod_to_pre_prod_data_sync_access_to_refined_zone_key_statement_for_pre_prod = {
    sid     = "ProdToPreProdRefinedZoneDataSyncKeyAccess"
    effect  = "Allow"
    actions = local.prod_to_preprod_kms_actions
    principals = {
      type        = "AWS"
      identifiers = [local.prod_to_preprod_sync_role_arn]
    }
  }

  prod_to_pre_prod_trusted_zone_data_sync_statement_for_pre_prod = {
    sid     = "ProdToPreProdTrustedZoneDataSyncAccess"
    effect  = "Allow"
    actions = local.prod_to_preprod_s3_actions
    resources = [
      "arn:aws:s3:::dataplatform-stg-trusted-zone",
      "arn:aws:s3:::dataplatform-stg-trusted-zone/*"
    ]
    principals = {
      type        = "AWS"
      identifiers = [local.prod_to_preprod_sync_role_arn]
    }
  }

  prod_to_pre_prod_data_sync_access_to_trusted_zone_key_statement_for_pre_prod = {
    sid     = "ProdToPreProdTrustedZoneDataSyncKeyAccess"
    effect  = "Allow"
    actions = local.prod_to_preprod_kms_actions
    principals = {
      type        = "AWS"
      identifiers = [local.prod_to_preprod_sync_role_arn]
    }
  }

  #-----------------------------------------------------------------------------
  # Housing Reporting Role Policies
  #-----------------------------------------------------------------------------

  housing_reporting_role_arn = "arn:aws:sts::${local.housing_account_id}:assumed-role/LBH_Reporting_Data_Sync_Role/export_dynamo_db_table"

  share_kms_key_with_housing_reporting_role = {
    sid    = "Allow use of KMS key by housing reporting role"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    principals = {
      type        = "AWS"
      identifiers = [local.housing_reporting_role_arn]
    }
    resources = ["*"]
  }

  allow_housing_reporting_role_access_to_landing_zone_path = {
    sid    = "Allow MTFH PITR Export to access landing zone paths"
    effect = "Allow"
    principals = {
      type        = "AWS"
      identifiers = [local.housing_reporting_role_arn]
    }
    actions = [
      "s3:AbortMultipartUpload",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-prod-landing-zone",
      "arn:aws:s3:::dataplatform-prod-landing-zone/mtfh/*"
    ]
  }

  allow_housing_reporting_role_access_to_landing_zone_path_pre_prod = {
    sid    = "Allow MTFH PITR Export to access landing zone paths"
    effect = "Allow"
    principals = {
      type        = "AWS"
      identifiers = [local.housing_reporting_role_arn]
    }
    actions = [
      "s3:AbortMultipartUpload",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::dataplatform-stg-landing-zone",
      "arn:aws:s3:::dataplatform-stg-landing-zone/mtfh/*"
    ]
  }

  #-----------------------------------------------------------------------------
  # Academy Account Policies
  #-----------------------------------------------------------------------------

  allow_access_from_academy_account = {
    sid    = "Allow access from academy account"
    effect = "Allow"
    principals = {
      type        = "AWS"
      identifiers = [var.academy_data_source_arn]
    }
    actions = [
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      module.landing_zone.bucket_arn,
      "${module.landing_zone.bucket_arn}/ieg4/*"
    ]
  }

  share_kms_key_with_academy_account = {
    sid    = "Allow use of KMS key by academy account"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    principals = {
      type        = "AWS"
      identifiers = [var.academy_data_source_arn]
    }
    resources = ["*"]
  }

  #-----------------------------------------------------------------------------
  # S3 Service Access to KMS Policies
  #-----------------------------------------------------------------------------

  s3_service_kms_conditions = [
    {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.data_platform.account_id]
    }
  ]

  allow_s3_access_to_raw_zone_kms_key = {
    sid    = "Allow Amazon S3 use of the customer managed key"
    effect = "Allow"
    principals = {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    conditions = concat(local.s3_service_kms_conditions, [
      {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = [module.raw_zone.bucket_arn]
      }
    ])
  }

  allow_s3_access_to_refined_zone_kms_key = {
    sid    = "Allow Amazon S3 use of the customer managed key"
    effect = "Allow"
    principals = {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    conditions = concat(local.s3_service_kms_conditions, [
      {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = [module.refined_zone.bucket_arn]
      }
    ])
  }

  allow_s3_access_to_trusted_zone_kms_key = {
    sid    = "Allow Amazon S3 use of the customer managed key"
    effect = "Allow"
    principals = {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    conditions = concat(local.s3_service_kms_conditions, [
      {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = [module.trusted_zone.bucket_arn]
      }
    ])
  }

  #-----------------------------------------------------------------------------
  # Admin Bucket Policies
  #-----------------------------------------------------------------------------

  grant_s3_write_permission_to_admin_bucket = {
    sid    = "Allow S3 write permission to admin bucket"
    effect = "Allow"
    principals = {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${module.admin_bucket.bucket_arn}/*"]
    conditions = [
      {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values = [
          module.raw_zone.bucket_arn,
          module.refined_zone.bucket_arn,
          module.trusted_zone.bucket_arn
        ]
      },
      {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.data_platform.account_id]
      },
      {
        test     = "StringEquals"
        variable = "s3:x-amz-acl"
        values   = ["bucket-owner-full-control"]
      }
    ]
  }
}
