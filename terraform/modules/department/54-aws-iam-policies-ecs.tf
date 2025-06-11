# =============================================================================
# ECS IAM POLICIES
# =============================================================================
# This file contains all ECS-related IAM policies for the department module.
# 
# Policies included:
# - ECS assume role policy
# - ECS department policy (composite)
# =============================================================================

# =============================================================================
# ECS ASSUME ROLE POLICY
# =============================================================================

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    sid    = "EcsAssumeRole"
    effect = "Allow"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# =============================================================================
# ECS DEPARTMENT POLICY (COMPOSITE)
# =============================================================================
# This policy combines multiple policy documents for ECS tasks

data "aws_iam_policy_document" "ecs_department_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.read_glue_scripts_and_mwaa_and_athena.json,
    data.aws_iam_policy_document.crawler_can_access_jdbc_connection.json
  ]
}

resource "aws_iam_policy" "department_ecs_policy" {
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-ecs-base-policy")
  policy = data.aws_iam_policy_document.ecs_department_policy.json
  tags   = var.tags
} 