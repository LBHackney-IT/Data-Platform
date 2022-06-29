resource "google_service_account" "service_account" {
  count = var.is_live_environment ? 1 : 0

  account_id   = lower("${var.identifier_prefix}${var.department_name}")
  display_name = "${var.application} - ${title(var.department_name)}"
  project      = var.google_project_id
}

resource "time_rotating" "key_rotation" {
  rotation_days = 35
}

resource "google_service_account_key" "json_credentials" {
  count = var.is_live_environment ? 1 : 0

  service_account_id = google_service_account.service_account[0].name
  public_key_type    = "TYPE_X509_PEM_FILE"

  keepers = {
    # Arbitrary map of values that, when changed, will trigger a new key to be generated
    # The key will only output the first time this resources is created, afterward it will have a null value
    secret_id     = aws_secretsmanager_secret.sheets_credentials.id
    rotation_time = time_rotating.key_rotation.rotation_days
  }
}
