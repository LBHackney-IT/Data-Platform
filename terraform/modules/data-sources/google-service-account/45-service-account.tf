data "google_service_account" "service_account" {
  count      = var.is_live_environment ? 1 : 0
  account_id = lower("${var.identifier_prefix}${var.department_name}")
}

data "google_service_account_key" "json_credentials" {
  count = var.is_live_environment ? 1 : 0
  name  = data.google_service_account.service_account[0].name
}
