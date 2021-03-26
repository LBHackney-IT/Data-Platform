resource "google_project" "data_platform_staging" {
  name       = "Data Platform Staging"
  project_id = lower("${var.team}-${var.project}-${var.environment}")
  org_id  = "127397986651"
}

resource "google_project_service" "data_platform_sheets_api" {
  project = google_project.data_platform_staging.id
  service = "sheets.googleapis.com"

  disable_dependent_services = true
}

resource "google_service_account" "housing" {
  account_id   = lower("${var.team}-${var.environment}-housing")
  display_name = "Dataplatform housing service account"
  project = google_project.data_platform_staging.id
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "user:${google_service_account.housing.email}",
    ]
  }
}
resource "google_service_account_iam_policy" "admin-account-iam" {
  service_account_id = google_service_account.housing.name
  policy_data        = data.google_iam_policy.admin.policy_data
}