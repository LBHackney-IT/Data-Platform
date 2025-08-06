// WARNING! All statement blocks MUST have a UNIQUE SID, this is to allow the individual documents to be merged.
// Statement blocks with the same SID will replace each other when merged.

// =============================================================================
// DEPARTMENT IAM MODULE
// =============================================================================

module "department_iam" {
  source = "./modules/department-iam"
  
  department_identifier    = local.department_identifier
  environment             = var.environment
  region                  = var.region
  identifier_prefix       = var.identifier_prefix
  short_identifier_prefix = var.short_identifier_prefix
  tags                    = var.tags
  
  bucket_configs = {
    landing_zone_bucket = var.landing_zone_bucket
    raw_zone_bucket     = var.raw_zone_bucket
    refined_zone_bucket = var.refined_zone_bucket
    trusted_zone_bucket = var.trusted_zone_bucket
    athena_storage_bucket = var.athena_storage_bucket
    glue_scripts_bucket = var.glue_scripts_bucket
    spark_ui_output_storage_bucket = var.spark_ui_output_storage_bucket
    glue_temp_storage_bucket = var.glue_temp_storage_bucket
  }
  
  mwaa_key_arn                      = var.mwaa_key_arn
  mwaa_etl_scripts_bucket_arn       = var.mwaa_etl_scripts_bucket_arn
  secrets_manager_kms_key_arn       = var.secrets_manager_kms_key.arn
  redshift_secret_arn               = aws_secretsmanager_secret.redshift_cluster_credentials.arn
  google_service_account_secret_arn = module.google_service_account.credentials_secret.arn
  
  create_airflow_user = var.departmental_airflow_user
  create_notebook     = local.create_notebook
  
  # Notebook variables (only used if create_notebook is true)
  notebook_role_arn           = local.create_notebook ? module.sagemaker[0].notebook_role_arn : ""
  notebook_arn                = local.create_notebook ? module.sagemaker[0].notebook_arn : ""
  lifecycle_configuration_arn = local.create_notebook ? module.sagemaker[0].lifecycle_configuration_arn : ""
  notebook_name               = local.create_notebook ? module.sagemaker[0].notebook_name : ""
  
  additional_s3_access = var.additional_s3_access
  cloudtrail_bucket    = var.cloudtrail_bucket
}

// =============================================================================
// LEGACY RESOURCE ALIASES (for backward compatibility)
// =============================================================================

# Create aliases for resources that other parts of the module reference
resource "aws_iam_policy" "read_only_s3_access" {
  tags = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-read-only-s3-department-access")
  policy = module.department_iam.policy_documents.read_only_s3_department_access
}

resource "aws_iam_policy" "read_only_glue_access" {
  tags = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-read-only-glue-access")
  policy = module.department_iam.policy_documents.read_only_glue_access
}

resource "aws_iam_policy" "s3_access" {
  tags = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-s3-department-access")
  policy = module.department_iam.policy_documents.s3_department_access
}

resource "aws_iam_policy" "glue_access" {
  tags = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-glue-access")
  policy = module.department_iam.policy_documents.glue_access
}

resource "aws_iam_policy" "secrets_manager_read_only" {
  tags = var.tags
  name   = lower("${var.identifier_prefix}-${local.department_identifier}-secrets-manager-read-only")
  policy = module.department_iam.policy_documents.secrets_manager_read_only
}

# Alias for data sources that other parts reference
data "aws_iam_policy_document" "sso_staging_user_policy" {
  source_policy_documents = [module.department_iam.sso_staging_user_policy_json]
}

data "aws_iam_policy_document" "sso_production_user_policy" {
  source_policy_documents = [module.department_iam.sso_production_user_policy_json]
}

data "aws_iam_policy_document" "athena_can_write_to_s3" {
  source_policy_documents = [module.department_iam.policy_documents.athena_can_write_to_s3]
}

data "aws_iam_policy_document" "redshift_department_read_access" {
  source_policy_documents = [module.department_iam.policy_documents.redshift_department_read_access]
}

data "aws_iam_policy_document" "mwaa_department_web_server_access" {
  source_policy_documents = [module.department_iam.policy_documents.mwaa_department_web_server_access]
}

data "aws_iam_policy_document" "notebook_access" {
  count = local.create_notebook ? 1 : 0
  source_policy_documents = [module.department_iam.policy_documents.notebook_access]
}