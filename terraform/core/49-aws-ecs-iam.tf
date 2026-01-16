# ==============================================================================
# Cross-Department Glue Metadata Role and Permissions:
# This role is used by ECS tasks to collect metadata from AWS Glue Catalog and S3
# and store it in the metastore database.
# ==============================================================================

# IAM Role for Cross-Department Glue Metadata
resource "aws_iam_role" "cross_department_glue_metadata_role" {
  name = "${local.identifier_prefix}-cross-department-glue-metadata-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = module.tags.values
}

# Glue Permissions Policy
data "aws_iam_policy_document" "cross_dept_glue_metadata_glue_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:catalog",
      "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:database/metastore",
      "arn:aws:glue:${var.aws_deploy_region}:${var.aws_deploy_account_id}:table/metastore/*"
    ]
  }
}

resource "aws_iam_policy" "cross_dept_glue_metadata_glue_permissions" {
  name   = "${local.identifier_prefix}-cross-dept-glue-metadata-glue"
  policy = data.aws_iam_policy_document.cross_dept_glue_metadata_glue_permissions.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "cross_dept_glue_metadata_glue_attach" {
  role       = aws_iam_role.cross_department_glue_metadata_role.name
  policy_arn = aws_iam_policy.cross_dept_glue_metadata_glue_permissions.arn
}

# Athena Permissions Policy
data "aws_iam_policy_document" "cross_dept_glue_metadata_athena_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:ListTableMetadata"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cross_dept_glue_metadata_athena_permissions" {
  name   = "${local.identifier_prefix}-cross-dept-glue-metadata-athena"
  policy = data.aws_iam_policy_document.cross_dept_glue_metadata_athena_permissions.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "cross_dept_glue_metadata_athena_attach" {
  role       = aws_iam_role.cross_department_glue_metadata_role.name
  policy_arn = aws_iam_policy.cross_dept_glue_metadata_athena_permissions.arn
}

# S3 Permissions Policy
data "aws_iam_policy_document" "cross_dept_glue_metadata_s3_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }

  # Write access only to raw zone and Athena storage (data-and-insight prefix)
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.raw_zone.bucket_arn}/data-and-insight/dataplatform_metadata/catalog_metadata/*",
      "${module.athena_storage.bucket_arn}/data-and-insight/temp/*"
    ]
  }
}

resource "aws_iam_policy" "cross_dept_glue_metadata_s3_permissions" {
  name   = "${local.identifier_prefix}-cross-dept-glue-metadata-s3"
  policy = data.aws_iam_policy_document.cross_dept_glue_metadata_s3_permissions.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "cross_dept_glue_metadata_s3_attach" {
  role       = aws_iam_role.cross_department_glue_metadata_role.name
  policy_arn = aws_iam_policy.cross_dept_glue_metadata_s3_permissions.arn
}

# KMS Permissions Policy
data "aws_iam_policy_document" "cross_dept_glue_metadata_kms_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }

  # Encrypt/GenerateDataKey only for raw zone and Athena storage (for writing)
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      module.raw_zone.kms_key_arn,
      module.athena_storage.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "cross_dept_glue_metadata_kms_permissions" {
  name   = "${local.identifier_prefix}-cross-dept-glue-metadata-kms"
  policy = data.aws_iam_policy_document.cross_dept_glue_metadata_kms_permissions.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "cross_dept_glue_metadata_kms_attach" {
  role       = aws_iam_role.cross_department_glue_metadata_role.name
  policy_arn = aws_iam_policy.cross_dept_glue_metadata_kms_permissions.arn
}


data "aws_iam_policy_document" "cross_dept_glue_metadata_secrets_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_deploy_region}:${var.aws_deploy_account_id}:secret:airflow/variables/*"
    ]
  }
}

resource "aws_iam_policy" "cross_dept_glue_metadata_secrets_permissions" {
  name   = "${local.identifier_prefix}-cross-dept-glue-metadata-secrets"
  policy = data.aws_iam_policy_document.cross_dept_glue_metadata_secrets_permissions.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "cross_dept_glue_metadata_secrets_attach" {
  role       = aws_iam_role.cross_department_glue_metadata_role.name
  policy_arn = aws_iam_policy.cross_dept_glue_metadata_secrets_permissions.arn
}
