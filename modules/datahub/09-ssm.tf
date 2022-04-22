resource "aws_ssm_parameter" "datahub_password" {
  name  = "/${var.short_identifier_prefix}/datahub/datahub_password"
  type  = "SecureString"
  value = random_password.datahub_secret.result
  tags = merge(var.tags, {
    "Name" : "Datahub Password"
  })
}