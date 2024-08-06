// WARNING! All statement blocks MUST have a UNIQUE SID, this is to allow the individual documents to be merged.
// Statement blocks with the same SID will replace each other when merged.

// S3 read only access policy
data "aws_iam_policy_document" "read_only_s3_department_access" {
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
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      var.landing_zone_bucket.kms_key_arn,
      var.raw_zone_bucket.kms_key_arn,
      var.refined_zone_bucket.kms_key_arn,
      var.trusted_zone_bucket.kms_key_arn,
      var.athena_storage_bucket.kms_key_arn,
      var.glue_scripts_bucket.kms_key_arn,
      var.spark_ui_output_storage_bucket.kms_key_arn
    ]
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
    resources = [

      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/${local.department_identifier}/*",

      var.glue_scripts_bucket.bucket_arn,
      "${var.glue_scripts_bucket.bucket_arn}/*",

      var.landing_zone_bucket.bucket_arn,
      "${var.landing_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/manual/*",

      var.raw_zone_bucket.bucket_arn,
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.raw_zone_bucket.bucket_arn}/unrestricted/*",

      var.refined_zone_bucket.bucket_arn,
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",

      var.trusted_zone_bucket.bucket_arn,
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.trusted_zone_bucket.bucket_arn}/unrestricted/*",

      var.spark_ui_output_storage_bucket.bucket_arn,
      "${var.spark_ui_output_storage_bucket.bucket_arn}/${local.department_identifier}/*"
    ]
  }

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
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-read-only-s3-department-access")
  policy = data.aws_iam_policy_document.read_only_s3_department_access.json
}

// Glue read only access policy
data "aws_iam_policy_document" "read_only_glue_access" {
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

  // Glue Access
  statement {
    sid = "AwsGlue"
    actions = [
      "glue:Batch*",
      "glue:CheckSchemaVersionValidity",
      "glue:Get*",
      "glue:List*",
      "glue:SearchTables",
      "glue:Query*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "read_only_glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-read-only-glue-access")
  policy = data.aws_iam_policy_document.read_only_glue_access.json
}

// Full departmental S3 access policy
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
      var.athena_storage_bucket.kms_key_arn,
      var.glue_scripts_bucket.kms_key_arn,
      var.spark_ui_output_storage_bucket.kms_key_arn,
      var.glue_temp_storage_bucket.kms_key_arn
    ]
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
      var.landing_zone_bucket.bucket_arn,
      "${var.landing_zone_bucket.bucket_arn}/${local.department_identifier}/manual/*",
      "${var.landing_zone_bucket.bucket_arn}/unrestricted/*",

      var.raw_zone_bucket.bucket_arn,
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.raw_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.raw_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.raw_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",

      var.refined_zone_bucket.bucket_arn,
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",

      var.trusted_zone_bucket.bucket_arn,
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}_$folder$",
      "${var.trusted_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",

      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/${local.department_identifier}/*",
      var.glue_temp_storage_bucket.bucket_arn,

      var.spark_ui_output_storage_bucket.bucket_arn,
      "${var.spark_ui_output_storage_bucket.bucket_arn}/${local.department_identifier}/*"
    ]
  }

  statement {
    sid    = "ReadAllScripts"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      var.glue_scripts_bucket.bucket_arn,
      "${var.glue_scripts_bucket.bucket_arn}/*",
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
      "${var.raw_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",

      "${var.refined_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.refined_zone_bucket.bucket_arn}/unrestricted/*",
      "${var.refined_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",

      "${var.trusted_zone_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.trusted_zone_bucket.bucket_arn}/quality-metrics/department=${local.department_identifier}/*",
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
      "${var.spark_ui_output_storage_bucket.bucket_arn}/${local.department_identifier}/*",
      "${var.glue_scripts_bucket.bucket_arn}/scripts/${local.department_identifier}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-s3-department-access")
  policy = data.aws_iam_policy_document.s3_department_access.json
}

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
      var.athena_storage_bucket.kms_key_arn,
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
      var.athena_storage_bucket.bucket_arn,
      "${var.athena_storage_bucket.bucket_arn}/primary/*",
      "${var.athena_storage_bucket.bucket_arn}/${local.department_identifier}/*"
    ]
  }
}

// Departmental Glue access policy
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
      "glue:StartWorkflowRun",
      "glue:StopCrawler",
      "glue:StopCrawlerSchedule",
      "glue:StopTrigger",
      "glue:StopWorkflowRun",
      "glue:TagResource",
      "glue:UpdateDag",
      "glue:UpdateDevEndpoint",
      "glue:UpdateJob",
      "glue:UpdateTable",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:GetTableVersions",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:Query*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_access" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-access")
  policy = data.aws_iam_policy_document.glue_access.json
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
      aws_secretsmanager_secret.redshift_cluster_credentials.arn,
      module.google_service_account.credentials_secret.arn,
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.identifier_prefix}/${local.department_identifier}/*",
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.short_identifier_prefix}/${local.department_identifier}*"
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

// Glue Agent write to cloudwatch policy
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

//Glue agent policy needed for dev endpoint
data "aws_iam_policy_document" "full_s3_access_to_glue_resources" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::crawler-public*",
      "arn:aws:s3:::aws-glue*"
    ]
  }
}

resource "aws_iam_policy" "full_s3_access_to_glue_resources" {
  tags = var.tags

  name   = "${var.identifier_prefix}-${local.department_identifier}-full-s3-access-to-glue-resources"
  policy = data.aws_iam_policy_document.full_s3_access_to_glue_resources.json
}

// Crawler can access JDBC Glue connection
data "aws_iam_policy_document" "crawler_can_access_jdbc_connection" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVPCs",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeRouteTables",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["aws-glue-service-resource"]
    }
    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:instance/*",
    ]
  }
}

resource "aws_iam_policy" "crawler_can_access_jdbc_connection" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-crawler-can-access-jdbc-connection")
  policy = data.aws_iam_policy_document.crawler_can_access_jdbc_connection.json
}

data "aws_iam_policy_document" "notebook_access" {
  count = local.create_notebook ? 1 : 0

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
      module.sagemaker[0].notebook_role_arn,
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
      module.sagemaker[0].notebook_arn,
      module.sagemaker[0].lifecycle_configuration_arn
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
      "arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:/aws/sagemaker/NotebookInstances:log-stream:${module.sagemaker[0].notebook_name}*"
    ]
  }
}

//glue-watermarks dynamodb access

resource "aws_iam_policy" "glue_access_to_watermarks_table" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-can-access-wartermarks-table")
  policy = data.aws_iam_policy_document.glue_access_to_watermarks_table.json
}

data "aws_iam_policy_document" "glue_access_to_watermarks_table" {

  statement {
    sid    = "ListAndDescribe"
    effect = "Allow"
    actions = [
      "dynamodb:List*",
      "dynamodb:DescribeReservedCapacity*",
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "SpecificTable"
    effect = "Allow"
    actions = [
      "dynamodb:BatchGet*",
      "dynamodb:DescribeStream",
      "dynamodb:DescribeTable",
      "dynamodb:Get*",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchWrite*",
      "dynamodb:CreateTable",
      #"dynamodb:Delete*",
      "dynamodb:Update*",
      "dynamodb:PutItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.short_identifier_prefix}glue-watermarks"]
  }

}

//Redshfift

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
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-runner-pass-role-to-glue-for-notebook-use")
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
      "glue:GetPartitions",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetCrawlers",
      "glue:GetCrawlerMetrics",
      "glue:GetCrawler",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable"
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

  statement {
    sid    = "AirflowPassRolePolicy"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      # A temporary solution (using mannually created role - test_hackney_ecs), we should replace with the actual terrafomed ecs task role
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/test_hackney_ecs"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "airflow_base_policy" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-${local.department_identifier}-ariflow-base-policy")
  policy = data.aws_iam_policy_document.airflow_base_policy.json
}
