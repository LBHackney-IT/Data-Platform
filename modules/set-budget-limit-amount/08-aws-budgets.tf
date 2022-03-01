resource "aws_budgets_budget" "actual_cost_budget" {
  name         = lower("${var.identifier_prefix}actual-cost-budget")
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
    threshold                  = "110"
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.emails_to_notify
  }
}

resource "aws_budgets_budget" "forecast_cost_budget" {
  name         = lower("${var.identifier_prefix}forecast-cost-budget")
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
    threshold                  = "110"
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.emails_to_notify
  }
}