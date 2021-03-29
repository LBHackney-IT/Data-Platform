# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "email_service_account" {
  description = "Email service account for housing"
  value       = google_service_account.housing.email
}

output "email_service_account_key" {
  description = "Private Key for the Housing Google Service account"
  value       = google_service_account_key.housing_json_credentials.private_key
}
