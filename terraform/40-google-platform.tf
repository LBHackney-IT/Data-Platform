resource "google_project_service" "sheets_api" {
  count = local.is_live_environment ? 1 : 0

  project                    = var.google_project_id
  service                    = "sheets.googleapis.com"
  disable_dependent_services = true
}
