// =============================================================================
// SSO USER POLICIES (using IAM module outputs)
// =============================================================================

// User Role for staging account - This role is a combination of policies ready to be applied to SSO
data "aws_iam_policy_document" "sso_staging_user_policy" {
  source_policy_documents = [module.department_iam.sso_staging_user_policy_json]
}

// User Role for production account - This role is a combination of policies ready to be applied to SSO
data "aws_iam_policy_document" "sso_production_user_policy" {
  source_policy_documents = [module.department_iam.sso_production_user_policy_json]
}

// =============================================================================
// ROLE REFERENCES (for backward compatibility)
// =============================================================================

# Create local references for roles managed by the IAM module
locals {
  glue_agent_role_arn = module.department_iam.glue_agent_role_arn
  glue_agent_role_name = module.department_iam.glue_agent_role_name
  department_ecs_role_arn = module.department_iam.ecs_task_role_arn
  department_ecs_role_name = module.department_iam.ecs_task_role_name
  airflow_user_arn = module.department_iam.airflow_user_arn
  airflow_user_name = module.department_iam.airflow_user_name
}