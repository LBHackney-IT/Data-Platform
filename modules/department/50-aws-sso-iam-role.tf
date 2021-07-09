// S3 access policy
data "aws_iam_policy_document" "s3_access" {
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
      "${var.refined_zone_bucket.bucket_arn}/${department_identifier}/*",
      var.trusted_zone_bucket.bucket_arn,
      "${var.trusted_zone_bucket.bucket_arn}/${department_identifier}/*",
      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/${department_identifier}/*",
      "${var.landing_zone_bucket.bucket_arn}/${department_identifier}/manual/*",
      "${var.raw_zone_bucket.bucket_arn}/${department_identifier}/*"
    ]
  }

  statement {
    sid    = "S3DeleteObject"
    effect = "Allow"
    actions = [
      "s3:Delete*"
    ]
    resources = [
      "${var.landing_zone_bucket.bucket_arn}/${department_identifier}/manual/*",
      "${var.raw_zone_bucket.bucket_arn}/${department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${department_identifier}/*",
      "${var.glue_temp_storage_bucket.bucket_arn}/${department_identifier}/*"
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
      "${var.raw_zone_bucket.bucket_arn}/${department_identifier}/*",
      var.landing_zone_bucket.bucket_arn,
      "${var.landing_zone_bucket.bucket_arn}/${department_identifier}/*",
    ]
  }

  statement {
    sid    = "List"
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
      "${var.glue_temp_storage_bucket.bucket_arn}/${department_identifier}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${department_identifier}-s3-access")
  policy = data.aws_iam_policy_document.s3_access.json
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
      "glue:BatchCreatePartition",
      "glue:BatchDeleteConnection",
      "glue:BatchDeletePartition",
      "glue:BatchDeleteTable",
      "glue:BatchDeleteTableVersion",
      "glue:BatchGetCrawlers",
      "glue:BatchGetDevEndpoints",
      "glue:BatchGetJobs",
      "glue:BatchGetPartition",
      "glue:BatchGetTriggers",
      "glue:BatchGetWorkflows",
      "glue:BatchStopJobRun",
      //      "glue:CancelMLTaskRun",
      "glue:CheckSchemaVersionValidity",
      //      "glue:CreateClassifier",
      //      "glue:CreateConnection",
      //      "glue:CreateCrawler",
      "glue:CreateDag",
      //      "glue:CreateDatabase",
      "glue:CreateDevEndpoint",
      "glue:CreateJob",
      //      "glue:CreateMLTransform",
      //      "glue:CreatePartition",
      //      "glue:CreateRegistry",
      //      "glue:CreateSchema",
      "glue:CreateScript",
      //      "glue:CreateSecurityConfiguration",
      "glue:CreateSession",
      //      "glue:CreateTable",
      "glue:CreateTrigger",
      //      "glue:CreateUserDefinedFunction",
      //      "glue:CreateWorkflow",
      //      "glue:DeleteClassifier",
      //      "glue:DeleteConnection",
      //      "glue:DeleteCrawler",
      //      "glue:DeleteDatabase",
      "glue:DeleteDevEndpoint",
      "glue:DeleteJob",
      //      "glue:DeleteMLTransform",
      //      "glue:DeletePartition",
      //      "glue:DeleteRegistry",
      //      "glue:DeleteResourcePolicy",
      //      "glue:DeleteSchema",
      //      "glue:DeleteSchemaVersions",
      //      "glue:DeleteSecurityConfiguration",
      //      "glue:DeleteTable",
      //      "glue:DeleteTableVersion",
      //      "glue:DeleteTrigger",
      //      "glue:DeleteUserDefinedFunction",
      //      "glue:DeleteWorkflow",
      "glue:GetCatalogImportStatus",
      "glue:GetClassifier",
      "glue:GetClassifiers",
      "glue:GetConnection",
      "glue:GetConnections",
      "glue:GetCrawler",
      "glue:GetCrawlerMetrics",
      "glue:GetCrawlers",
      "glue:GetDag",
      "glue:GetDataCatalogEncryptionSettings",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetDataflowGraph",
      "glue:GetDevEndpoint",
      "glue:GetDevEndpoints",
      "glue:GetInferredSchema",
      "glue:GetJob",
      "glue:GetJobBookmark",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:GetJobs",
      //      "glue:GetMLTaskRun",
      //      "glue:GetMLTaskRuns",
      //      "glue:GetMLTransform",
      //      "glue:GetMLTransforms",
      "glue:GetMapping",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetPlan",
      "glue:GetRegistry",
      "glue:GetResourcePolicies",
      "glue:GetResourcePolicy",
      "glue:GetSchema",
      "glue:GetSchemaByDefinition",
      "glue:GetSchemaVersion",
      "glue:GetSchemaVersionsDiff",
      "glue:GetSecurityConfiguration",
      "glue:GetSecurityConfigurations",
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions",
      "glue:GetTables",
      "glue:GetTags",
      "glue:GetTrigger",
      "glue:GetTriggers",
      "glue:GetUserDefinedFunction",
      "glue:GetUserDefinedFunctions",
      "glue:GetWorkflow",
      "glue:GetWorkflowRun",
      "glue:GetWorkflowRunProperties",
      "glue:GetWorkflowRuns",
      //      "glue:ImportCatalogToGlue",
      "glue:ListCrawlers",
      "glue:ListDevEndpoints",
      "glue:ListJobs",
      "glue:ListMLTransforms",
      "glue:ListRegistries",
      "glue:ListSchemaVersions",
      "glue:ListSchemas",
      "glue:ListTriggers",
      "glue:ListWorkflows",
      //      "glue:PutDataCatalogEncryptionSettings",
      //      "glue:PutResourcePolicy",
      //      "glue:PutSchemaVersionMetadata",
      //      "glue:PutWorkflowRunProperties",
      //      "glue:QuerySchemaVersionMetadata",
      //      "glue:RegisterSchemaVersion",
      //      "glue:RemoveSchemaVersionMetadata",
      "glue:ResetJobBookmark",
      //      "glue:ResumeWorkflowRun",
      "glue:SearchTables",
      "glue:StartCrawler",
      "glue:StartCrawlerSchedule",
      "glue:StartExportLabelsTaskRun",
      "glue:StartImportLabelsTaskRun",
      "glue:StartJobRun",
      //      "glue:StartMLEvaluationTaskRun",
      //      "glue:StartMLLabelingSetGenerationTaskRun",
      //      "glue:StartTrigger",
      "glue:StartWorkflowRun",
      "glue:StopCrawler",
      "glue:StopCrawlerSchedule",
      "glue:StopTrigger",
      "glue:StopWorkflowRun",
      "glue:TagResource",
      //      "glue:UntagResource",
      //      "glue:UpdateClassifier",
      //      "glue:UpdateConnection",
      //      "glue:UpdateCrawler",
      //      "glue:UpdateCrawlerSchedule",
      "glue:UpdateDag",
      //      "glue:UpdateDatabase",
      "glue:UpdateDevEndpoint",
      "glue:UpdateJob",
      //      "glue:UpdateMLTransform",
      //      "glue:UpdatePartition",
      //      "glue:UpdateRegistry",
      //      "glue:UpdateSchema",
      //      "glue:UpdateTable",
      "glue:UpdateTrigger",
      //      "glue:UpdateUserDefinedFunction",
      //      "glue:UpdateWorkflow",
      //      "glue:UseMLTransforms",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${department_identifier}-glue-access")
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
      aws_secretsmanager_secret.redshift_cluster_parking_credentials.arn,
      module.google_service_account.credentials_secret.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key_id
    ]
  }
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${department_identifier}-secrets-manager-read-only")
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

  name   = lower("${var.identifier_prefix}-${department_identifier}-glue-scripts-read-only")
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

  name   = "${var.identifier_prefix}-${department_identifier}-glue-cloudwatch"
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

  name   = lower("${var.identifier_prefix}-${department_identifier}-full-glue-access")
  policy = data.aws_iam_policy_document.full_glue_access.json
}

// User Role - This role is a combination of all the rules ready to be applied to sso.
data "aws_iam_policy_document" "sso_user_policy" {
  override_policy_documents = [
    data.aws_iam_policy_document.s3_access,
    data.aws_iam_policy_document.glue_access,
    data.aws_iam_policy_document.secrets_manager_read_only
  ]
}

resource "aws_iam_policy" "sso_user_policy" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${department_identifier}-sso-user-policy")
  policy = data.aws_iam_policy_document.sso_user_policy.json
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

  name               = lower("${var.identifier_prefix}-glue-${department_identifier}")
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