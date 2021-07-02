output "email" {
  value = google_service_account.service_account.email
}

output "credentials_secret_name" {
  value = aws_secretsmanager_secret.sheets_credentials.name
}