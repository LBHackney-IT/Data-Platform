# resource "google_project" "google_project" {
#   name       = "${var.application} ${var.environment}"
#   project_id = lower("${local.application_snake}-${var.environment}")
#   org_id     = "127397986651"
# }

# resource "google_project_service" "sheets_api" {
#   project = google_project.google_project.id
#   service = "sheets.googleapis.com"

#   disable_dependent_services = true
# }

# data "google_iam_policy" "project_admin" {
#   binding {
#     role = "roles/admin"

#     members = [
#       "user:maysa.kanoni@hackney.gov.uk",
#       "user:matt.bee@hackney.gov.uk",
#       "user:james.oates@hackney.gov.uk",
#       "user:ben.dalton@hackney.gov.uk"
#     ]
#   }
# }

# resource "google_project_iam_policy" "project_iam" {
#   project     = google_project.google_project.project_id
#   policy_data = data.google_iam_policy.project_admin.policy_data
# }
