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


module "aws_budget" {
  source = "github.com/LBHackney-IT/ce-aws-budgets-lbh"

  budget_name               = "Athena Daily Budget Alert"
  budget_type               = "COST"
  limit_amount              = "3"
  time_unit                 = "DAILY"

  cost_filter = [
    {
      name   = "Service"
      values = ["Amazon Athena"]
    }
  ]

  comparison_operator       = "GREATER_THAN"
  threshold                 = 100
  threshold_type            = "PERCENTAGE"
  notification_type         = "ACTUAL"
  subscriber_email_address  = var.emails_to_notify_with_budget_alerts
}
