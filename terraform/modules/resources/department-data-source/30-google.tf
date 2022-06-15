data "google_project" "project" {}

module "google_service_account" {
  source              = "../google-service-account-data-source"
  is_live_environment = var.is_live_environment
  department_name     = local.department_identifier
  identifier_prefix   = var.short_identifier_prefix
}
