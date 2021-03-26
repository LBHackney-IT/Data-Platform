resource "google_project" "data_platform_staging" {
  name = "${var.application} ${var.environment}"
  project_id = local.identifier_prefix
  org_id = "127397986651"
}

resource "google_project_service" "data_platform_sheets_api" {
  project = google_project.data_platform_staging.id
  service = "sheets.googleapis.com"

  disable_dependent_services = true
}

resource "google_service_account" "housing" {
  account_id = lower("${local.application_snake}-${var.environment}-housing")
  display_name = "Dataplatform housing service account"
  project = google_project.data_platform_staging.project_id
}

# data "google_iam_policy" "admin" {
#   binding {
#     role = "roles/iam.serviceAccountUser"

#     members = [
#       "serviceAccount:${google_service_account.housing.email}",
#     ]
#   }
# }

# resource "google_service_account_iam_policy" "admin_account_iam" {
#   service_account_id = google_service_account.housing.name
#   policy_data        = data.google_iam_policy.admin.policy_data
# }

resource "google_project_iam_policy" "project_iam" {
  project = google_project.data_platform_staging.project_id
  policy_data = data.google_iam_policy.project_admin.policy_data
}

data "google_iam_policy" "project_admin" {
  binding {
    role = "roles/admin"

    members = [
      "user:maysa.kanoni@hackney.gov.uk",
      "user:matt.bee@hackney.gov.uk",
      "user:james.oates@hackney.gov.uk"
    ]
  }
}
