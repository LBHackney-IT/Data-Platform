output "email" {
  value = length(data.google_service_account.service_account) == 1 ? data.google_service_account.service_account[0].email : ""
}

output "credentials_secret" {
  value = data.aws_secretsmanager_secret.sheets_credentials
}