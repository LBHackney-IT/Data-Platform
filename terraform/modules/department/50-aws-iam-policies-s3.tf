# =============================================================================
# S3 IAM POLICIES
# =============================================================================
# This file contains all S3-related IAM policies for the department module.
# 
# Policies included:
# - Read-only S3 department access
# - Full S3 department access  
# - Athena S3 write access
# - MTFH S3 access (conditional)
# =============================================================================

# -----------------------------------------------------------------------------
# LOCALS FOR S3 RESOURCE PATTERNS
# -----------------------------------------------------------------------------
locals {
  # Common S3 resource patterns for department access
  department_s3_resources = {
    landing_zone = [
      var.landing_zone_bucket.bucket_arn,
      "${var.landing_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/manual/*",
    ]
    
    raw_zone = [
      var.raw_zone_bucket.bucket_arn,
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.raw_zone_bucket.bucket_arn}/unrestricted/*",
    ]
    
    refined_zone = [
      var.refined_zone_bucket.bucket_arn,
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",
    ]
    
    trusted_zone = [
      var.trusted_zone_bucket.bucket_arn,
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.trusted_zone_bucket.bucket_arn}/unrestricted/*",
    ]
    
    athena_storage = [
      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/${local.department_identifier}/*",
    ]
    
    spark_ui_output = [
      var.spark_ui_output_storage_bucket.bucket_arn,
      "${var.spark_ui_output_storage_bucket.bucket_arn}/${local.department_identifier}/*"
    ]
    
    glue_scripts = [
      var.glue_scripts_bucket.bucket_arn,
      "${var.glue_scripts_bucket.bucket_arn}/*",
    ]
  }

  # KMS keys for S3 buckets
  department_kms_keys = [
    var.landing_zone_bucket.kms_key_arn,
    var.raw_zone_bucket.kms_key_arn,
    var.refined_zone_bucket.kms_key_arn,
    var.trusted_zone_bucket.kms_key_arn,
    var.athena_storage_bucket.kms_key_arn,
    var.glue_scripts_bucket.kms_key_arn,
    var.spark_ui_output_storage_bucket.kms_key_arn
  ]

  # All read-only S3 resources
  read_only_s3_resources = flatten([
    local.department_s3_resources.landing_zone,
    local.department_s3_resources.raw_zone,
    local.department_s3_resources.refined_zone,
    local.department_s3_resources.trusted_zone,
    local.department_s3_resources.athena_storage,
    local.department_s3_resources.spark_ui_output,
    local.department_s3_resources.glue_scripts,
  ])
}

# =============================================================================
# READ-ONLY S3 DEPARTMENT ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "read_only_s3_department_access" {
  # Allow listing all S3 buckets and KMS aliases
  statement {
    sid    = "ListAllS3AndKmsKeys"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "kms:ListAliases",
    ]
    resources = ["*"]
  }

  # KMS key access for department buckets (read-only)
  statement {
    sid    = "KmsKeyReadOnlyAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = local.department_kms_keys
  }

  # Additional KMS access for external buckets
  dynamic "statement" {
    for_each = var.additional_s3_access
    iterator = additional_access_item
    content {
      sid    = "AdditionalKmsReadOnlyAccess${replace(additional_access_item.value.bucket_arn, "/[^a-zA-Z0-9]/", "")}"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = [additional_access_item.value.kms_key_arn]
    }
  }

  # Read access to department areas in all buckets
  statement {
    sid    = "S3ReadAllDepartmentAreasInBuckets"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:List*",
    ]
    resources = local.read_only_s3_resources
  }

  # Additional S3 read-only access for external buckets
  dynamic "statement" {
    for_each = var.additional_s3_access
    iterator = additional_access_item
    content {
      sid    = "AdditionalS3ReadOnlyAccess${replace(additional_access_item.value.bucket_arn, "/[^a-zA-Z0-9]/", "")}"
      effect = "Allow"
      actions = [
        "s3:Get*",
        "s3:List*",
      ]
      resources = concat(
        [additional_access_item.value.bucket_arn],
        additional_access_item.value.paths == null ? [
          "${additional_access_item.value.bucket_arn}/*"
        ] : [
          for path in additional_access_item.value.paths : "${additional_access_item.value.bucket_arn}/${path}/*"
        ]
      )
    }
  }

  # Write access to manual folder in landing zone
  statement {
    sid    = "S3WriteToManualFolder"
    effect = "Allow"
    actions = [
      "s3:Put*",
      "s3:Delete*"
    ]
    resources = [
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/manual/*",
    ]
  }
}

resource "aws_iam_policy" "read_only_s3_access" {
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-read-only-s3-department-access")
  policy = data.aws_iam_policy_document.read_only_s3_department_access.json
}

# =============================================================================
# FULL S3 DEPARTMENT ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "s3_department_access" {
  # Allow listing all S3 buckets and KMS aliases
  statement {
    sid    = "ListAllS3AndKmsKeys"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "kms:ListAliases",
    ]
    resources = ["*"]
  }

  # Full KMS key access for department buckets
  statement {
    sid    = "KmsKeyFullAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = concat(
      local.department_kms_keys,
      [
        var.glue_temp_storage_bucket.kms_key_arn,
        var.mwaa_key_arn
      ]
    )
  }

  # Additional KMS full access for external buckets
  dynamic "statement" {
    for_each = var.additional_s3_access
    iterator = additional_access_item
    content {
      sid    = "AdditionalKmsFullAccess${replace(additional_access_item.value.bucket_arn, "/[^a-zA-Z0-9]/", "")}"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:RetireGrant"
      ]
      resources = [additional_access_item.value.kms_key_arn]
    }
  }

  # Read and write access to department areas
  statement {
    sid    = "S3ReadAndWrite"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:List*",
      "s3:PutObject",
    ]
    resources = flatten([
      local.read_only_s3_resources,
      [
        "${var.raw_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
        var.glue_temp_storage_bucket.bucket_arn,
        var.mwaa_etl_scripts_bucket_arn,
        "${var.mwaa_etl_scripts_bucket_arn}/${replace(local.department_identifier, "-", "_")}/*",
        "${var.mwaa_etl_scripts_bucket_arn}/unrestricted/*",
        "${var.mwaa_etl_scripts_bucket_arn}/shared/*",
      ]
    ])
  }

  # Additional S3 full access for external buckets
  dynamic "statement" {
    for_each = var.additional_s3_access
    iterator = additional_access_item
    content {
      sid     = "AdditionalS3FullAccess${replace(additional_access_item.value.bucket_arn, "/[^a-zA-Z0-9]/", "")}"
      effect  = "Allow"
      actions = additional_access_item.value.actions
      resources = concat(
        [additional_access_item.value.bucket_arn],
        additional_access_item.value.paths == null ? [
          "${additional_access_item.value.bucket_arn}/*"
        ] : [
          for path in additional_access_item.value.paths : "${additional_access_item.value.bucket_arn}/${path}/*"
        ]
      )
    }
  }

  # Read all scripts (separate from general read/write)
  statement {
    sid    = "ReadAllScripts"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = local.department_s3_resources.glue_scripts
  }

  # Delete access to specific paths
  statement {
    sid    = "S3DeleteObject"
    effect = "Allow"
    actions = [
      "s3:Delete*"
    ]
    resources = [
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/manual/*",
      "${var.landing_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.raw_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.raw_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
    ]
  }

  # Full access to specific areas
  statement {
    sid    = "FullAccess"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${var.glue_scripts_bucket.bucket_arn}/custom/*",
      "${var.glue_temp_storage_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.spark_ui_output_storage_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.glue_scripts_bucket.bucket_arn}/scripts/${local.department_identifier}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-s3-department-access")
  policy = data.aws_iam_policy_document.s3_department_access.json
}

# =============================================================================
# ATHENA S3 WRITE ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "athena_can_write_to_s3" {
  # KMS access for Athena storage
  statement {
    sid    = "KmsKeyAthenaStorageAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    resources = [
      var.athena_storage_bucket.kms_key_arn,
    ]
  }

  # S3 write access for Athena storage
  statement {
    sid    = "AthenaStorageS3Write"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:PutObject",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/primary/*",
      "${var.athena_storage_bucket.bucket_arn}/${local.department_identifier}/*"
    ]
  }
}

# Note: This policy document is used in other files, not exported as a standalone policy

# =============================================================================
# MTFH S3 ACCESS POLICY (CONDITIONAL)
# =============================================================================

data "aws_iam_policy_document" "mtfh_access" {
  count = contains(["data-and-insight", "housing"], local.department_identifier) ? 1 : 0

  statement {
    sid    = "S3ReadMtfhDirectory"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
    ]
    resources = [
      "${var.landing_zone_bucket.bucket_arn}/mtfh/*",
      var.landing_zone_bucket.bucket_arn
    ]
  }
}

resource "aws_iam_policy" "mtfh_access_policy" {
  count       = contains(["data-and-insight", "housing"], local.department_identifier) ? 1 : 0
  name        = lower("${var.identifier_prefix}-${local.department_identifier}-mtfh-landing-access-policy")
  description = "Allows ${local.department_identifier} department access for ecs tasks to mtfh/ subdirectory in landing zone"
  policy      = data.aws_iam_policy_document.mtfh_access[0].json
  tags        = var.tags
} 