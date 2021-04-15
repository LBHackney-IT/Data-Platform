resource "google_project" "data_platform_staging" {
  name       = "Data Platform Staging"
  project_id = lower("${var.team}-${var.project}-${var.environment}")
  org_id  = "127397986651"
}
