# =============================================================================
# MISCELLANEOUS IAM POLICIES
# =============================================================================
# This file contains miscellaneous IAM policies for the department module
# that don't fit into other service-specific categories.
# 
# Policies included:
# - Redshift department read access
# - Notebook access (conditional)
# =============================================================================

# =============================================================================
# REDSHIFT DEPARTMENT READ ACCESS POLICY
# =============================================================================

data "aws_iam_policy_document" "redshift_department_read_access" {
  # Redshift cluster access
  statement {
    sid    = "RedshiftClusterAccess"
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

  # SQL Workbench access
  statement {
    sid    = "SqlWorkbenchAccess"
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

# Note: This policy document is used in role composition, not exported as standalone policy

# =============================================================================
# NOTEBOOK ACCESS POLICY (CONDITIONAL)
# =============================================================================

data "aws_iam_policy_document" "notebook_access" {
  count = local.create_notebook ? 1 : 0

  # General notebook listing and resource access
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

  # Role passing for notebook
  statement {
    sid     = "CanPassRoleToNotebook"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      module.sagemaker[0].notebook_role_arn,
    ]
  }

  # Departmental notebook management
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

  # CloudWatch Logs access for notebook
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

  # Read notebook logs
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

# Note: This policy document is used in role composition, not exported as standalone policy 