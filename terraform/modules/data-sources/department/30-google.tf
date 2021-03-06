data "google_project" "project" {}

module "google_service_account_data_source" {
  source              = "../google-service-account"
  is_live_environment = var.is_live_environment
  department_name     = local.department_identifier
  identifier_prefix   = var.short_identifier_prefix
}
