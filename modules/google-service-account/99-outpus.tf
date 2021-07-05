output "email" {
  value = length(google_service_account.service_account) == 1 ? google_service_account.service_account[0].email : ""
}

output "credentials_secret" {
  value = aws_secretsmanager_secret.sheets_credentials
}