resource "google_project_service" "sheets_api" {
  project = var.google_project_id
  service = "sheets.googleapis.com"

  disable_dependent_services = true
}

# data "google_iam_policy" "project_admin" {
#   binding {
#     role = "roles/admin"

#     members = [
#       "user:maysa.kanoni@hackney.gov.uk",
#       "user:matt.bee@hackney.gov.uk",
#       "user:james.oates@hackney.gov.uk",
#       "user:ben.dalton@hackney.gov.uk",
#       "user:elena.vilimaite@hackney.gov.uk"
#     ]
#   }
# }

# resource "google_project_iam_policy" "project_iam" {
#   project     = var.google_project_id
#   policy_data = data.google_iam_policy.project_admin.policy_data
# }
