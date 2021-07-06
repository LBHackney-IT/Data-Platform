data "google_project" "project" {}

module "google_service_account" {
  source                     = "../google-service-account"
  is_live_environment        = var.is_live_environment
  department_name            = local.department_identifier
  identifier_prefix          = var.identifier_prefix
  application                = var.application
  google_project_id          = data.google_project.project.project_id
  secrets_manager_kms_key_id = var.secrets_manager_kms_key_id
  tags                       = var.tags
}
