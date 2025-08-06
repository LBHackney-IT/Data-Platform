// =============================================================================
// SPECIALIZED POLICIES (Athena, Secrets, MWAA, Notebook, etc.)
// =============================================================================

// Prod departmental S3 access policy to write to athena storage
data "aws_iam_policy_document" "athena_can_write_to_s3" {
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
      var.bucket_configs.athena_storage_bucket.kms_key_arn,
    ]
  }

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
      var.bucket_configs.athena_storage_bucket.bucket_arn,
      "${var.bucket_configs.athena_storage_bucket.bucket_arn}/primary/*",
      "${var.bucket_configs.athena_storage_bucket.bucket_arn}/${var.department_identifier}/*"
    ]
  }
}

// Read only Secrets policy
data "aws_iam_policy_document" "secrets_manager_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.redshift_secret_arn,
      var.google_service_account_secret_arn,
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.identifier_prefix}/${var.department_identifier}/*",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.short_identifier_prefix}/${var.department_identifier}*",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:airflow/variables/env-fxe5CD",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:airflow/variables/env-jeCYYl",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-secrets-manager-read-only")
  policy = data.aws_iam_policy_document.secrets_manager_read_only.json
}

//Redshift
data "aws_iam_policy_document" "redshift_department_read_access" {
  statement {
    effect = "Allow"
    actions = [
      "redshift:DescribeClusters",
      "redshift:DescribeClusterSnapshots",
      "redshift:DescribeEvents",
      "redshift-serverless:ListNamespaces",
      "redshift-serverless:ListWorkgroups"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqlworkbench:GetAccountInfo",
      "sqlworkbench:GetAccountSettings",
      "sqlworkbench:GetUserInfo",
      "sqlworkbench:GetUserWorkspaceSettings"
    ]
    resources = ["*"]
  }
}

// MWAA Access
data "aws_iam_policy_document" "mwaa_department_web_server_access" {
  statement {
    effect = "Allow"

    actions = [
      "airflow:ListEnvironments",
      "airflow:GetEnvironment",
      "airflow:ListTagsForResource",
      "airflow:CreateWebLoginToken"
    ]

    resources = ["*"]
  }
}

// Notebook access policy
data "aws_iam_policy_document" "notebook_access" {
  count = var.create_notebook ? 1 : 0

  statement {
    sid    = "CanListAllNotebooksAndRelatedResources"
    effect = "Allow"
    actions = [
      "sagemaker:ListNotebookInstances",
      "sagemaker:ListCodeRepositories",
      "sagemaker:ListTags",
      "sagemaker:DescribeCodeRepository",
      "sagemaker:ListNotebookInstanceLifecycleConfigs"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "CanPassRoleToNotebook"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      var.notebook_role_arn,
    ]
  }

  statement {
    sid    = "CanStartAndOpenDepartmentalNotebook"
    effect = "Allow"
    actions = [
      "sagemaker:StartNotebookInstance",
      "sagemaker:StopNotebookInstance",
      "sagemaker:CreatePresignedNotebookInstanceUrl",
      "sagemaker:DescribeNotebookInstance",
      "sagemaker:CreatePresignedDomainUrl",
      "sagemaker:DescribeNotebookInstanceLifecycleConfig"
    ]
    resources = [
      var.notebook_arn,
      var.lifecycle_configuration_arn
    ]
  }

  statement {
    sid    = "CanListNotebookLogStreams"
    effect = "Allow"
    actions = [
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/NotebookInstances:*"
    ]
  }

  statement {
    sid    = "CanReadNotebookLogs"
    effect = "Allow"
    actions = [
      "logs:GetLogEvents",
      "logs:GetLogRecord"
    ]
    resources = [
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/NotebookInstances:log-stream:${var.notebook_name}*"
    ]
  }
}

// Glue job runner pass role to glue for notebook use
data "aws_iam_policy_document" "glue_runner_pass_role_to_glue_for_notebook_use" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.glue_agent.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "glue_runner_pass_role_to_glue_for_notebook_use" {
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${var.department_identifier}-glue-runner-pass-role-to-glue-for-notebook-use")
  policy = data.aws_iam_policy_document.glue_runner_pass_role_to_glue_for_notebook_use.json
}

# create a base policy for the departmental airflow user
data "aws_iam_policy_document" "airflow_base_policy" {
  statement {
    sid    = "AirflowLogsPolicy"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AirflowGluePolicy"
    effect = "Allow"
    actions = [
      "glue:UpdateCrawlerSchedule",
      "glue:UpdateCrawler",
      "glue:StopCrawler",
      "glue:StartCrawler",
      "glue:ListCrawlers",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:DeletePartitionIndex",
      "glue:UpdatePartition",
      "glue:DeletePartition",
      "glue:BatchCreatePartition",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetCrawlers",
      "glue:GetCrawlerMetrics",
      "glue:GetCrawler",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetJobRuns"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AirflowAthenaPolicy"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:ListDatabases",
      "athena:ListTableMetadata",
      "athena:GetTableMetadata"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AirflowKmsPolicy"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    # This can be refined later but not urgent
    resources = ["*"]
  }

  statement {
    sid    = "AirflowEcsPolicy"
    effect = "Allow"
    actions = [
      "ecs:*"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*"
    ]
  }
}

resource "aws_iam_policy" "airflow_base_policy" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${var.department_identifier}-airflow-base-policy")
  policy = data.aws_iam_policy_document.airflow_base_policy.json
}

data "aws_iam_policy_document" "department_ecs_passrole" {
  statement {
    sid    = "AirflowDepartmentECSPassrolePolicy"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.department_ecs_role.arn,                                                                               # Defined in roles-ecs.tf
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.department_identifier}-ecs-execution-role", # Defined in ecs repo.
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "department_ecs_passrole" {
  name   = lower("${var.identifier_prefix}-${var.department_identifier}-department-ecs-passrole")
  policy = data.aws_iam_policy_document.department_ecs_passrole.json
  tags   = var.tags
}

# ECS Department task role policy
data "aws_iam_policy_document" "ecs_department_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.read_glue_scripts_and_mwaa_and_athena.json,
    data.aws_iam_policy_document.crawler_can_access_jdbc_connection.json
  ]
}

resource "aws_iam_policy" "department_ecs_policy" {
  name   = lower("${var.identifier_prefix}-${var.department_identifier}-ecs-base-policy")
  policy = data.aws_iam_policy_document.ecs_department_policy.json
  tags   = var.tags
}

// s3 access for mtfh data in landing zone
data "aws_iam_policy_document" "mtfh_access" {
  count = contains(["data-and-insight", "housing"], var.department_identifier) ? 1 : 0

  statement {
    sid    = "S3ReadMtfhDirectory"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
    ]
    resources = [
      "${var.bucket_configs.landing_zone_bucket.bucket_arn}/mtfh/*",
      var.bucket_configs.landing_zone_bucket.bucket_arn
    ]
  }
}

resource "aws_iam_policy" "mtfh_access_policy" {
  count       = contains(["data-and-insight", "housing"], var.department_identifier) ? 1 : 0
  name        = lower("${var.identifier_prefix}-${var.department_identifier}-mtfh-landing-access-policy")
  description = "Allows ${var.department_identifier} department access for ecs tasks to mtfh/ subdirectory in landing zone"
  policy      = data.aws_iam_policy_document.mtfh_access[0].json
  tags        = var.tags
}