module "set_budget_limit_amount" {
  source                         = "../modules/set-budget-limit-amount"
  tags                           = module.tags.values
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  lambda_name                    = "set_budget_limit_amount"
  service_area                   = "housing"
  account_id                     = data.aws_caller_identity.data_platform.account_id
}

resource "aws_budgets_budget" "actual_cost_budget" {
  name         = "actual-cost-budget"
  budget_type  = "COST"
  limit_amount = "1000" # Initial value. Will be overwritten by the scheduled lambda function
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  lifecycle {
    ignore_changes = [
      limit_amount,
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = "100"
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [
      "saml-aws-data-platform-admins@hackney.gov.uk"
      ]
  }
}

resource "aws_budgets_budget" "forecast_cost_budget" {
  name         = "forecast-cost-budget"
  budget_type  = "COST"
  limit_amount = "1000" # Initial value. Will be overwritten by the scheduled lambda function
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  lifecycle {
    ignore_changes = [
      limit_amount,
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = "100"
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [
      "saml-aws-data-platform-admins@hackney.gov.uk"
    ]
  }
}