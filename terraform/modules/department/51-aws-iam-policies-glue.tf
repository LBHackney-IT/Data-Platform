# =============================================================================
# GLUE IAM POLICIES
# =============================================================================
# This file contains all Glue-related IAM policies for the department module.
# 
# Policies included:
# - Read-only Glue access
# - Full Glue access
# - Glue CloudWatch access
# - Glue JDBC connection access
# - Glue S3 resources access
# - Glue watermarks DynamoDB access
# - Glue runner pass role policy
# =============================================================================

# =============================================================================
# READ-ONLY GLUE ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "read_only_glue_access" {
  # General AWS service access for Glue operations
  statement {
    sid    = "GeneralAwsServiceAccess"
    effect = "Allow"
    actions = [
      "athena:*",
      "logs:DescribeLogGroups",
      "tag:GetResources",
      "iam:ListRoles",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs access for Glue
  statement {
    sid    = "GlueLogsAccess"
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

  # Read-only Glue service access
  statement {
    sid = "AwsGlueReadOnly"
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
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-read-only-glue-access")
  policy = data.aws_iam_policy_document.read_only_glue_access.json
}

# =============================================================================
# FULL GLUE ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "glue_access" {
  # General AWS service access for Glue operations
  statement {
    sid    = "GeneralAwsServiceAccess"
    effect = "Allow"
    actions = [
      "athena:*",
      "logs:DescribeLogGroups",
      "tag:GetResources",
      "iam:ListRoles",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs access for Glue
  statement {
    sid    = "GlueLogsAccess"
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

  # Role permissions for Glue agent
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

  # Allow role passing to Glue jobs
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

  # Full Glue service access
  statement {
    sid = "AwsGlueFull"
    actions = [
      "glue:Batch*",
      "glue:CheckSchemaVersionValidity",
      "glue:CreateDevEndpoint",
      "glue:CreateJob",
      "glue:CreateScript",
      "glue:CreateSession",
      "glue:CreatePartition",
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
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-access")
  policy = data.aws_iam_policy_document.glue_access.json
}

# =============================================================================
# GLUE CLOUDWATCH ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "glue_can_write_to_cloudwatch" {
  # CloudWatch Logs permissions for Glue
  statement {
    sid    = "CloudWatchLogsAccess"
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

  # CloudWatch Metrics permissions
  statement {
    sid    = "CloudWatchMetricsAccess"
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
  tags   = var.tags
  name   = "${var.identifier_prefix}-${local.department_identifier}-glue-cloudwatch"
  policy = data.aws_iam_policy_document.glue_can_write_to_cloudwatch.json
}

# =============================================================================
# FULL GLUE SERVICE ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "full_glue_access" {
  statement {
    sid    = "FullGlueAccess"
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
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-full-glue-access")
  policy = data.aws_iam_policy_document.full_glue_access.json
}

# =============================================================================
# GLUE S3 RESOURCES ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "full_s3_access_to_glue_resources" {
  statement {
    sid    = "GlueS3ResourcesAccess"
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
  tags   = var.tags
  name   = "${var.identifier_prefix}-${local.department_identifier}-full-s3-access-to-glue-resources"
  policy = data.aws_iam_policy_document.full_s3_access_to_glue_resources.json
}

# =============================================================================
# GLUE JDBC CONNECTION ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "crawler_can_access_jdbc_connection" {
  # VPC and networking permissions for JDBC connections
  statement {
    sid    = "VpcNetworkingAccess"
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

  # EC2 tagging permissions for Glue-managed resources
  statement {
    sid    = "Ec2TaggingAccess"
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
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-crawler-can-access-jdbc-connection")
  policy = data.aws_iam_policy_document.crawler_can_access_jdbc_connection.json
}

# =============================================================================
# GLUE SCRIPTS AND ATHENA ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "read_glue_scripts_and_mwaa_and_athena" {
  # Athena access for Glue jobs
  statement {
    sid    = "GlueAthenaAccess"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:ListDatabases",
      "athena:ListTableMetadata",
      "athena:GetTableMetadata",
      "athena:GetWorkGroup",
    ]
    resources = ["*"]
  }

  # Read-only access to Glue scripts
  statement {
    sid    = "GlueScriptsReadOnly"
    effect = "Allow"
    actions = [
      "s3:Get*"
    ]
    resources = [
      "${var.glue_scripts_bucket.bucket_arn}/*"
    ]
  }

  # KMS access for Glue scripts
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

resource "aws_iam_policy" "read_glue_scripts_and_mwaa_and_athena" {
  name        = lower("${var.identifier_prefix}-${local.department_identifier}-read-glue-scripts-and-mwaa-and-athena")
  description = "IAM policy for Glue scripts read-only, specific Athena actions, and read access to MWAA S3 bucket"
  tags        = var.tags
  policy      = data.aws_iam_policy_document.read_glue_scripts_and_mwaa_and_athena.json
}

# =============================================================================
# GLUE WATERMARKS DYNAMODB ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "glue_access_to_watermarks_table" {
  # General DynamoDB permissions
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

  # Specific table permissions for watermarks
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
      "dynamodb:Update*",
      "dynamodb:PutItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/${var.short_identifier_prefix}glue-watermarks"]
  }
}

resource "aws_iam_policy" "glue_access_to_watermarks_table" {
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-can-access-wartermarks-table")
  policy = data.aws_iam_policy_document.glue_access_to_watermarks_table.json
}

# =============================================================================
# GLUE RUNNER PASS ROLE POLICY (FOR NOTEBOOK USE)
# =============================================================================

data "aws_iam_policy_document" "glue_runner_pass_role_to_glue_for_notebook_use" {
  statement {
    sid    = "PassRoleToGlue"
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