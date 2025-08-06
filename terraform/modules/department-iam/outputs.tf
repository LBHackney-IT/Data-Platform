// =============================================================================
// ROLE OUTPUTS
// =============================================================================

output "glue_agent_role_arn" {
  description = "ARN of the Glue agent role"
  value       = aws_iam_role.glue_agent.arn
}

output "glue_agent_role_name" {
  description = "Name of the Glue agent role"
  value       = aws_iam_role.glue_agent.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.department_ecs_role.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.department_ecs_role.name
}

// =============================================================================
// POLICY OUTPUTS
// =============================================================================

output "policy_arns" {
  description = "Map of all policy ARNs"
  value = {
    s3_read_only                       = aws_iam_policy.read_only_s3_access.arn
    s3_full_access                     = aws_iam_policy.s3_access.arn
    glue_read_only                     = aws_iam_policy.read_only_glue_access.arn
    glue_full_access                   = aws_iam_policy.glue_access.arn
    glue_agent_full_access             = aws_iam_policy.full_glue_access.arn
    secrets_manager_read_only          = aws_iam_policy.secrets_manager_read_only.arn
    glue_cloudwatch                    = aws_iam_policy.glue_can_write_to_cloudwatch.arn
    glue_scripts_and_athena            = aws_iam_policy.read_glue_scripts_and_mwaa_and_athena.arn
    crawler_jdbc_connection            = aws_iam_policy.crawler_can_access_jdbc_connection.arn
    glue_s3_resources                  = aws_iam_policy.full_s3_access_to_glue_resources.arn
    glue_watermarks_table              = aws_iam_policy.glue_access_to_watermarks_table.arn
    airflow_base_policy                = aws_iam_policy.airflow_base_policy.arn
    department_ecs_passrole            = aws_iam_policy.department_ecs_passrole.arn
    department_ecs_policy              = aws_iam_policy.department_ecs_policy.arn
    glue_runner_pass_role_for_notebook = var.environment == "prod" ? null : aws_iam_policy.glue_runner_pass_role_to_glue_for_notebook_use.arn
    mtfh_access_policy                 = contains(["data-and-insight", "housing"], var.department_identifier) ? aws_iam_policy.mtfh_access_policy[0].arn : null
    cloudtrail_access_policy           = var.department_identifier == "data-and-insight" && var.cloudtrail_bucket != null ? aws_iam_policy.cloudtrail_access_policy[0].arn : null
  }
}

// =============================================================================
// SSO POLICY OUTPUTS (for migration)
// =============================================================================

output "sso_staging_user_policy_json" {
  description = "Combined policy document for SSO staging users"
  value       = data.aws_iam_policy_document.sso_staging_user_policy.json
}

output "sso_production_user_policy_json" {
  description = "Combined policy document for SSO production users"
  value       = data.aws_iam_policy_document.sso_production_user_policy.json
}

// =============================================================================
// AIRFLOW USER OUTPUTS
// =============================================================================

output "airflow_user_arn" {
  description = "ARN of the departmental airflow user (if created)"
  value       = var.create_airflow_user ? aws_iam_user.airflow_user[0].arn : null
}

output "airflow_user_name" {
  description = "Name of the departmental airflow user (if created)"
  value       = var.create_airflow_user ? aws_iam_user.airflow_user[0].name : null
}

output "airflow_user_secret_arn" {
  description = "ARN of the airflow user secret (if created)"
  value       = var.create_airflow_user ? aws_secretsmanager_secret.airflow_user_secret[0].arn : null
}

// =============================================================================
// POLICY DOCUMENT OUTPUTS (for inline policies)
// =============================================================================

output "policy_documents" {
  description = "Policy documents for inline attachment"
  value = {
    s3_department_access              = data.aws_iam_policy_document.s3_department_access.json
    read_only_s3_department_access    = data.aws_iam_policy_document.read_only_s3_department_access.json
    athena_can_write_to_s3            = data.aws_iam_policy_document.athena_can_write_to_s3.json
    glue_access                       = data.aws_iam_policy_document.glue_access.json
    read_only_glue_access             = data.aws_iam_policy_document.read_only_glue_access.json
    secrets_manager_read_only         = data.aws_iam_policy_document.secrets_manager_read_only.json
    redshift_department_read_access   = data.aws_iam_policy_document.redshift_department_read_access.json
    mwaa_department_web_server_access = data.aws_iam_policy_document.mwaa_department_web_server_access.json
    notebook_access                   = var.create_notebook ? data.aws_iam_policy_document.notebook_access[0].json : null
  }
}