module "set_budget_limit_amount" {
  source                         = "../modules/set-budget-limit-amount"
  tags                           = module.tags.values
  environment                    = var.environment
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "set_budget_limit_amount"
  service_area                   = "housing"
  account_id                     = data.aws_caller_identity.data_platform.account_id
  emails_to_notify               = var.emails_to_notify_with_budget_alerts
}

resource "aws_ssm_parameter" "budget_alert_recipients" {
  name      = "/data-and-insight/budget-alert-recipients"
  type      = "StringList"
  value     = "update_in_console@example.com"
  tags      = module.tags.values
  overwrite = true

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

data "aws_ssm_parameter" "budget_alert_recipients" {
  name = aws_ssm_parameter.budget_alert_recipients.name
}

