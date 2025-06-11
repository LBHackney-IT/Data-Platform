# =============================================================================
# AIRFLOW IAM POLICIES
# =============================================================================
# This file contains all Airflow-related IAM policies for the department module.
# 
# Policies included:
# - MWAA web server access
# - Airflow base policy
# - Department ECS pass role policy
# =============================================================================

# =============================================================================
# MWAA WEB SERVER ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "mwaa_department_web_server_access" {
  statement {
    sid    = "MwaaWebServerAccess"
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

# Note: This policy document is used in role composition, not exported as standalone policy

# =============================================================================
# AIRFLOW BASE POLICY
# =============================================================================

data "aws_iam_policy_document" "airflow_base_policy" {
  # CloudWatch Logs permissions for Airflow
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

  # Glue permissions for Airflow
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

  # Athena permissions for Airflow
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

  # KMS permissions for Airflow
  statement {
    sid    = "AirflowKmsPolicy"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    # This can be refined later but not urgent
    resources = ["*"]
  }

  # ECS permissions for Airflow
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
  tags   = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-airflow-base-policy")
  policy = data.aws_iam_policy_document.airflow_base_policy.json
}

# =============================================================================
# DEPARTMENT ECS PASS ROLE POLICY
# =============================================================================

data "aws_iam_policy_document" "department_ecs_passrole" {
  statement {
    sid    = "AirflowDepartmentECSPassrolePolicy"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.department_ecs_role.arn,                                                                                 # Defined in 50-aws-iam-roles.tf
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.department_identifier}-ecs-execution-role", # Defined in ecs repo.
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "department_ecs_passrole" {
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-department-ecs-passrole")
  policy = data.aws_iam_policy_document.department_ecs_passrole.json
  tags   = var.tags
} 