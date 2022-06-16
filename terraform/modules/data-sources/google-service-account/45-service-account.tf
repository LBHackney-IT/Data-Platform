data "google_service_account" "service_account" {
  count      = var.is_live_environment ? 1 : 0
  account_id = lower("${var.identifier_prefix}${var.department_name}")
}
