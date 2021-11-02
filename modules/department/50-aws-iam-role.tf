// WARNING! All statement blocks MUST have a UNIQUE SID, this is to allow the individual documents to be merged.
// Statement blocks with the same SID will replace each other when merged.

# When updating user roles, while this will be deployed to staging it won't update the role that the SSO users assume.
# To update the SSO role, you will need to ask the Cloud Engineering team responsible for maintaining the SSO
# to copy over the updated role to SSO.

// S3 access policy
data "aws_iam_policy_document" "s3_department_access" {
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
    resources = [
      var.landing_zone_bucket.kms_key_arn,
      var.raw_zone_bucket.kms_key_arn,
      var.refined_zone_bucket.kms_key_arn,
      var.trusted_zone_bucket.kms_key_arn,
      var.athena_storage_bucket.kms_key_arn
    ]
  }

  statement {
    sid    = "S3ReadAndWrite"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListJobs",
      "s3:ListMultipartUploadParts",
      "s3:ListStorageLensConfigurations",
      "s3:PutObject",
    ]
    resources = [
      var.refined_zone_bucket.bucket_arn,
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",
      var.trusted_zone_bucket.bucket_arn,
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/unrestricted/*",
      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/manual/*",
      "${var.landing_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.raw_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*"
    ]
  }

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
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.glue_temp_storage_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*"
    ]
  }

  statement {
    sid    = "S3ReadOnly"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      var.raw_zone_bucket.bucket_arn,
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.raw_zone_bucket.bucket_arn}/unrestricted/*",
      var.landing_zone_bucket.bucket_arn,
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.landing_zone_bucket.bucket_arn}/unrestricted/*",
    ]
  }

  statement {
    sid    = "S3List"
    effect = "Allow"
    actions = [
      "s3:List*"
    ]
    resources = [
      var.glue_temp_storage_bucket.bucket_arn,
      var.glue_scripts_bucket.bucket_arn,
    ]
  }

  statement {
    sid    = "FullAccess"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "${var.glue_scripts_bucket.bucket_arn}/custom/*",
      "${var.glue_temp_storage_bucket.bucket_arn}/${local.department_identifier}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-s3-department-access")
  policy = data.aws_iam_policy_document.s3_department_access.json
}

// Glue access policy
data "aws_iam_policy_document" "glue_access" {
  statement {
    effect = "Allow"
    actions = [
      "athena:*",
      "logs:DescribeLogGroups",
      "tag:GetResources",
      "iam:ListRoles",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:FilterLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }

  statement {
    sid    = "RolePermissions"
    effect = "Allow"
    actions = [
      "iam:GetRole",
    ]
    resources = [
      aws_iam_role.glue_agent.arn
    ]
  }

  statement {
    sid = "AllowRolePassingToGlueJobs"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.glue_agent.arn
    ]
    condition {
      test     = "StringLike"
      values   = ["glue.amazonaws.com"]
      variable = "iam:PassedToService"
    }
  }

  // Glue Access
  statement {
    sid = "AwsGlue"
    actions = [
      "glue:Batch*",
      "glue:CheckSchemaVersionValidity",
      "glue:CreateDag",
      "glue:CreateDevEndpoint",
      "glue:CreateJob",
      "glue:CreateScript",
      "glue:CreateSession",
      "glue:CreateTrigger",
      "glue:DeleteDevEndpoint",
      "glue:DeleteJob",
      "glue:DeleteTrigger",
      "glue:Get*",
      "glue:List*",
      "glue:ResetJobBookmark",
      "glue:SearchTables",
      "glue:StartCrawler",
      "glue:StartCrawlerSchedule",
      "glue:StartExportLabelsTaskRun",
      "glue:StartImportLabelsTaskRun",
      "glue:StartJobRun",
      "glue:StartTrigger",
      "glue:StartWorkflowRun",
      "glue:StopCrawler",
      "glue:StopCrawlerSchedule",
      "glue:StopTrigger",
      "glue:StopWorkflowRun",
      "glue:TagResource",
      "glue:UpdateDag",
      "glue:UpdateDevEndpoint",
      "glue:UpdateJob",
      "glue:UpdateTrigger",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-access")
  policy = data.aws_iam_policy_document.glue_access.json
}

// Secrets policy
data "aws_iam_policy_document" "secrets_manager_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      aws_secretsmanager_secret.redshift_cluster_credentials.arn,
      module.google_service_account.credentials_secret.arn,
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.identifier_prefix}/${local.department_identifier}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key.arn
    ]
  }
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-secrets-manager-read-only")
  policy = data.aws_iam_policy_document.secrets_manager_read_only.json
}

// Read only policy for glue scripts
data "aws_iam_policy_document" "glue_scripts_read_only" {
  statement {
    sid    = "ReadOnly"
    effect = "Allow"
    actions = [
      "s3:Get*",
    ]
    resources = [
      "${var.glue_scripts_bucket.bucket_arn}/*"
    ]
  }

  statement {
    sid    = "DecryptGlueScripts"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.glue_scripts_bucket.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "glue_scripts_read_only" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-scripts-read-only")
  policy = data.aws_iam_policy_document.glue_scripts_read_only.json
}

// Glue Agent cloudwatch
data "aws_iam_policy_document" "glue_can_write_to_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:AssociateKmsKey"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "glue_can_write_to_cloudwatch" {
  tags = var.tags

  name   = "${var.identifier_prefix}-${local.department_identifier}-glue-cloudwatch"
  policy = data.aws_iam_policy_document.glue_can_write_to_cloudwatch.json
}

// Glue Agent full access
data "aws_iam_policy_document" "full_glue_access" {
  statement {
    effect = "Allow"
    actions = [
      "glue:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "full_glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-full-glue-access")
  policy = data.aws_iam_policy_document.full_glue_access.json
}

// User Role - This role is a combination of all the rules ready to be applied to sso.
data "aws_iam_policy_document" "sso_user_policy" {
  override_policy_documents = [
    data.aws_iam_policy_document.s3_department_access.json,
    data.aws_iam_policy_document.glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json
  ]
}

// Glue role + attachments
data "aws_iam_policy_document" "glue_agent_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "glue_agent" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-glue-${local.department_identifier}")
  assume_role_policy = data.aws_iam_policy_document.glue_agent_assume_role.json
}

resource "aws_iam_role_policy_attachment" "glue_agent_s3_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "glue_agents_secrets_manager_read_only" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_can_write_to_cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_glue_scripts_read_only" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.glue_scripts_read_only.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_glue_can_write_to_cloudwatch" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}

resource "aws_iam_role_policy_attachment" "glue_agent_glue_full_access" {
  role       = aws_iam_role.glue_agent.name
  policy_arn = aws_iam_policy.full_glue_access.arn
}