# We make any output files clear by adding them to the 99-outputs.tf, meaning anyone can quickly check if they're consuming your module
output "email_service_account" {
  description = "Email service account for housing"
  value       = terraform.workspace == "default" ? google_service_account.service_account_housing[0].email : ""
}
