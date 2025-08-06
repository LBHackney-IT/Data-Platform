// Common resource patterns and action lists for department IAM
locals {
  # Common KMS keys for read-only access
  read_only_kms_keys = [
    var.bucket_configs.landing_zone_bucket.kms_key_arn,
    var.bucket_configs.raw_zone_bucket.kms_key_arn,
    var.bucket_configs.refined_zone_bucket.kms_key_arn,
    var.bucket_configs.trusted_zone_bucket.kms_key_arn,
    var.bucket_configs.athena_storage_bucket.kms_key_arn,
    var.bucket_configs.glue_scripts_bucket.kms_key_arn,
    var.bucket_configs.spark_ui_output_storage_bucket.kms_key_arn
  ]

  # Common KMS keys for full access
  full_access_kms_keys = concat(local.read_only_kms_keys, [
    var.bucket_configs.glue_temp_storage_bucket.kms_key_arn,
    var.mwaa_key_arn
  ])

  # Common S3 bucket resources for departmental access
  departmental_s3_resources = [
    # Landing zone
    var.bucket_configs.landing_zone_bucket.bucket_arn,
    "${var.bucket_configs.landing_zone_bucket.bucket_arn}/unrestricted/*",
    "${var.bucket_configs.landing_zone_bucket.bucket_arn}/${var.department_identifier}/manual/*",

    # Raw zone
    var.bucket_configs.raw_zone_bucket.bucket_arn,
    "${var.bucket_configs.raw_zone_bucket.bucket_arn}/${var.department_identifier}/*",
    "${var.bucket_configs.raw_zone_bucket.bucket_arn}/${var.department_identifier}_$folder$",
    "${var.bucket_configs.raw_zone_bucket.bucket_arn}/unrestricted/*",

    # Refined zone
    var.bucket_configs.refined_zone_bucket.bucket_arn,
    "${var.bucket_configs.refined_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",
    "${var.bucket_configs.refined_zone_bucket.bucket_arn}/${var.department_identifier}/*",
    "${var.bucket_configs.refined_zone_bucket.bucket_arn}/${var.department_identifier}_$folder$",
    "${var.bucket_configs.refined_zone_bucket.bucket_arn}/unrestricted/*",

    # Trusted zone
    var.bucket_configs.trusted_zone_bucket.bucket_arn,
    "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${var.department_identifier}/*",
    "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/${var.department_identifier}/*",
    "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/${var.department_identifier}_$folder$",
    "${var.bucket_configs.trusted_zone_bucket.bucket_arn}/unrestricted/*",

    # Other buckets
    var.bucket_configs.athena_storage_bucket.bucket_arn,
    "${var.bucket_configs.athena_storage_bucket.bucket_arn}/${var.department_identifier}/*",
    var.bucket_configs.spark_ui_output_storage_bucket.bucket_arn,
    "${var.bucket_configs.spark_ui_output_storage_bucket.bucket_arn}/${var.department_identifier}/*"
  ]

  # Common Glue actions for global operations
  glue_global_actions = [
    "glue:BatchGetCrawlers",
    "glue:BatchGetDevEndpoints",
    "glue:BatchGetJobs",
    "glue:BatchGetTriggers",
    "glue:BatchGetWorkflows",
    "glue:CheckSchemaVersionValidity",
    "glue:GetCrawler",
    "glue:GetCrawlers",
    "glue:GetCrawlerMetrics",
    "glue:GetDevEndpoint",
    "glue:GetDevEndpoints",
    "glue:GetJob",
    "glue:GetJobs",
    "glue:GetJobBookmark",
    "glue:GetJobRun",
    "glue:GetJobRuns",
    "glue:GetTrigger",
    "glue:GetTriggers",
    "glue:GetWorkflow",
    "glue:GetWorkflowRun",
    "glue:GetWorkflowRuns",
    "glue:GetSecurityConfiguration",
    "glue:GetSecurityConfigurations",
    "glue:GetConnection",
    "glue:GetConnections",
    "glue:GetClassifier",
    "glue:GetClassifiers",
    "glue:ListCrawlers",
    "glue:ListDevEndpoints",
    "glue:ListJobs",
    "glue:ListTriggers",
    "glue:ListWorkflows",
    "glue:ListClassifiers",
    "glue:ListSecurityConfigurations",
    "glue:SearchTables",
    "glue:QuerySchema"
  ]

  # Common Glue actions for database/table operations
  glue_database_read_actions = [
    "glue:GetDatabases",
    "glue:GetDatabase",
    "glue:GetTable",
    "glue:GetTables",
    "glue:GetTableVersion",
    "glue:GetTableVersions",
    "glue:GetPartition",
    "glue:GetPartitions",
    "glue:BatchGetPartition",
    "glue:GetUserDefinedFunction",
    "glue:GetUserDefinedFunctions"
  ]

  # Additional Glue actions for write operations
  glue_database_write_actions = [
    "glue:UpdateTable",
    "glue:CreateTable",
    "glue:DeleteTable",
    "glue:CreatePartition",
    "glue:DeletePartition",
    "glue:BatchCreatePartition",
    "glue:BatchDeletePartition",
    "glue:CreateUserDefinedFunction",
    "glue:UpdateUserDefinedFunction",
    "glue:DeleteUserDefinedFunction",
    "glue:UpdateDatabase",
    "glue:CreateDatabase",
    "glue:DeleteDatabase"
  ]

  # Common Glue resource ARNs for departmental access
  glue_departmental_resources = [
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/unrestricted",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${var.department_identifier}",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${var.department_identifier}_*",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/unrestricted/*",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.department_identifier}/*",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.department_identifier}_*/*",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/unrestricted/*",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/${var.department_identifier}/*",
    "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/${var.department_identifier}_*/*"
  ]
}

# Data sources needed for ARN construction
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}