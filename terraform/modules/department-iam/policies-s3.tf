// =============================================================================
// S3 ACCESS POLICIES
// =============================================================================

// S3 read only access policy
data "aws_iam_policy_document" "read_only_s3_department_access" {
  # Include CloudTrail bucket access for data-and-insight department
  source_policy_documents = var.department_identifier == "data-and-insight" && var.cloudtrail_bucket != null ? [
    data.aws_iam_policy_document.cloudtrail_access[0].json
  ] : []

  statement {
    sid    = "ListAllS3AndKmsKeys"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "kms:ListAliases",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "KmsKeyReadOnlyAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = local.read_only_kms_keys
  }

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

  statement {
    sid    = "S3ReadAllDepartmentAreasInBuckets"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:List*",
    ]
    resources = concat(local.departmental_s3_resources, [
      var.bucket_configs.glue_scripts_bucket.bucket_arn,
      "${var.bucket_configs.glue_scripts_bucket.bucket_arn}/*"
    ])
  }

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

  statement {
    sid    = "S3WriteToManualFolder"
    effect = "Allow"
    actions = [
      "s3:Put*",
      "s3:Delete*"
    ]
    resources = [
      "${var.bucket_configs.landing_zone_bucket.bucket_arn}/${var.department_identifier}/manual/*",
    ]
  }
}

resource "aws_iam_policy" "read_only_s3_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-read-only-s3-department-access")
  policy = data.aws_iam_policy_document.read_only_s3_department_access.json
}

// Full departmental S3 access policy
data "aws_iam_policy_document" "s3_department_access" {
  # Include CloudTrail bucket access for data-and-insight department
  source_policy_documents = var.department_identifier == "data-and-insight" && var.cloudtrail_bucket != null ? [
    data.aws_iam_policy_document.cloudtrail_access[0].json
  ] : []

  statement {
    sid    = "ListAllS3AndKmsKeys"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "kms:ListAliases",
    ]
    resources = ["*"]
  }

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
    resources = local.full_access_kms_keys
  }

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
    resources = [
      var.bucket_configs.landing_zone_bucket.bucket_arn,
      "${var.bucket_configs.landing_zone_bucket.bucket_arn}/${var.department_identifier}/manual/*",
      "${var.bucket_configs.landing_zone_bucket.bucket_arn}/unrestricted/*",

      var.bucket_configs.raw_zone_bucket.bucket_arn,
      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/${var.department_identifier}_$folder$",
      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",

      var.bucket_configs.refined_zone_bucket.bucket_arn,
      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/${var.department_identifier}_$folder$",
      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",

      var.bucket_configs.trusted_zone_bucket.bucket_arn,
      "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/${var.department_identifier}_$folder$",
      "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",

      var.bucket_configs.athena_storage_bucket.bucket_arn,
      "${var.bucket_configs.athena_storage_bucket.bucket_arn}/${var.department_identifier}/*",
      var.bucket_configs.glue_temp_storage_bucket.bucket_arn,

      var.bucket_configs.spark_ui_output_storage_bucket.bucket_arn,
      "${var.bucket_configs.spark_ui_output_storage_bucket.bucket_arn}/${var.department_identifier}/*",

      var.mwaa_etl_scripts_bucket_arn,
      "${var.mwaa_etl_scripts_bucket_arn}/${replace(var.department_identifier, "-", "_")}/*",
      "${var.mwaa_etl_scripts_bucket_arn}/unrestricted/*",
      "${var.mwaa_etl_scripts_bucket_arn}/shared/*"
    ]
  }

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

  statement {
    sid    = "ReadAllScripts"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      var.bucket_configs.glue_scripts_bucket.bucket_arn,
      "${var.bucket_configs.glue_scripts_bucket.bucket_arn}/*",
    ]
  }

  statement {
    sid    = "S3DeleteObject"
    effect = "Allow"
    actions = [
      "s3:Delete*"
    ]
    resources = [
      "${var.bucket_configs.landing_zone_bucket.bucket_arn}/${var.department_identifier}/manual/*",
      "${var.bucket_configs.landing_zone_bucket.bucket_arn}/unrestricted/*",

      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.bucket_configs.raw_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",

      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.bucket_configs.refined_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",

      "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",
    ]
  }

  statement {
    sid    = "FullAccess"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${var.bucket_configs.glue_scripts_bucket.bucket_arn}/custom/*",
      "${var.bucket_configs.glue_temp_storage_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.spark_ui_output_storage_bucket.bucket_arn}/${var.department_identifier}/*",
      "${var.bucket_configs.glue_scripts_bucket.bucket_arn}/scripts/${var.department_identifier}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-s3-department-access")
  policy = data.aws_iam_policy_document.s3_department_access.json
}

// Read-only CloudTrail access for Data and Insight department only
data "aws_iam_policy_document" "cloudtrail_access" {
  count = var.department_identifier == "data-and-insight" && var.cloudtrail_bucket != null ? 1 : 0

  statement {
    sid    = "CloudTrailKmsReadAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [var.cloudtrail_bucket.kms_key_arn]
  }

  statement {
    sid    = "CloudTrailS3ReadAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket"
    ]
    resources = [
      var.cloudtrail_bucket.bucket_arn,
      "${var.cloudtrail_bucket.bucket_arn}/*"
    ]
  }
}

resource "aws_iam_policy" "cloudtrail_access_policy" {
  count       = var.department_identifier == "data-and-insight" && var.cloudtrail_bucket != null ? 1 : 0
  name        = lower("${var.identifier_prefix}-${var.department_identifier}-cloudtrail-access-policy")
  description = "Allows ${var.department_identifier} department read-only access to CloudTrail bucket"
  policy      = data.aws_iam_policy_document.cloudtrail_access[0].json
  tags        = var.tags
}