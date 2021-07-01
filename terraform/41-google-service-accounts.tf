/* ==== SERVICE ACCOUNT - HOUSING =================================================================================== */
resource "google_service_account" "service_account_housing" {
  count        = local.is_live_environment ? 1 : 0
  account_id   = lower("${local.application_snake}-${var.environment}-housing")
  display_name = "${var.application} - Housing"
  project      = var.google_project_id
}

resource "time_rotating" "key_rotation_housing" {
  count         = local.is_live_environment ? 1 : 0
  rotation_days = 30
}

resource "google_service_account_key" "housing_json_credentials" {
  count              = local.is_live_environment ? 1 : 0
  service_account_id = google_service_account.service_account_housing[0].name
  public_key_type    = "TYPE_X509_PEM_FILE"

  keepers = {
    # Arbitrary map of values that, when changed, will trigger a new key to be generated
    secret_id     = aws_secretsmanager_secret.sheets_credentials_housing.id
    rotation_time = time_rotating.key_rotation_housing[0].rotation_rfc3339
  }
}

module "parking_google_service_account" {
  count                      = local.is_live_environment ? 1 : 0
  source                     = "./../modules/google-service-account"
  department_name            = "parking"
  identifier_prefix          = local.short_identifier_prefix
  application                = local.application_snake
  google_project_id          = var.google_project_id
  secrets_manager_kms_key_id = aws_kms_key.secrets_manager_key.key_id
  tags                       = module.tags.values
}
