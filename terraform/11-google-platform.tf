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
