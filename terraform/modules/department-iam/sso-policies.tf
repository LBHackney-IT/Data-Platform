// =============================================================================
// SSO USER POLICIES
// =============================================================================

// User Role for staging account - This role is a combination of policies ready to be applied to SSO
data "aws_iam_policy_document" "sso_staging_user_policy" {
  override_policy_documents = var.create_notebook ? [
    data.aws_iam_policy_document.s3_department_access.json,
    data.aws_iam_policy_document.glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.redshift_department_read_access.json,
    data.aws_iam_policy_document.notebook_access[0].json
    ] : [
    data.aws_iam_policy_document.s3_department_access.json,
    data.aws_iam_policy_document.glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.redshift_department_read_access.json,
    data.aws_iam_policy_document.mwaa_department_web_server_access.json
  ]
}

// User Role for production account - This role is a combination of policies ready to be applied to SSO
data "aws_iam_policy_document" "sso_production_user_policy" {
  override_policy_documents = [
    data.aws_iam_policy_document.read_only_s3_department_access.json,
    data.aws_iam_policy_document.read_only_glue_access.json,
    data.aws_iam_policy_document.secrets_manager_read_only.json,
    data.aws_iam_policy_document.athena_can_write_to_s3.json
  ]
}