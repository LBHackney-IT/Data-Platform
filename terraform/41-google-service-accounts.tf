/* ==== SERVICE ACCOUNT - HOUSING =================================================================================== */
resource "google_service_account" "service_account_housing" {
  count        = terraform.workspace == "default" ? 1 : 0
  account_id   = lower("${local.application_snake}-${var.environment}-housing")
  display_name = "${var.application} - Housing"
  project      = var.google_project_id
}

resource "time_rotating" "key_rotation_housing" {
  count         = terraform.workspace == "default" ? 1 : 0
  rotation_days = 30
}

resource "google_service_account_key" "housing_json_credentials" {
  count              = terraform.workspace == "default" ? 1 : 0
  service_account_id = google_service_account.service_account_housing[0].name
  public_key_type    = "TYPE_X509_PEM_FILE"

  keepers = {
    # Arbitrary map of values that, when changed, will trigger a new key to be generated
    rotation_time = time_rotating.key_rotation_housing[0].rotation_rfc3339
  }
}