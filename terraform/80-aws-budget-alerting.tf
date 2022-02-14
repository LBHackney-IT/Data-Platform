resource "aws_sns_topic" "budget_notification" {
  name = "budget_notification"
}

resource "aws_sns_topic_policy" "budget_notification_policy" {
  arn = aws_sns_topic.budget_notification

  policy = data.aws_iam_policy_document.budget_notification_policy.json
}

data "aws_iam_policy_document" "budget_notification_policy" {
  statement {
    actions = [
      "SNS:Publish"
    ]
    effect = "Allow"

    resources = [
      aws_sns_topic.budget_notification.arn
    ]

    principals {
      identifiers = [
        "budgets.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_budgets_budget" "all-cost-budget" {
  name         = "all-cost-budget"
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
    subscriber_email_addresses = ["ben.reynolds-carr@hackney.gov.uk"]
  }
}

resource "aws_budgets_budget" "monthly_cost_forecast" {
  name         = "monthly-cost-forecast"
  budget_type  = "COST"
  limit_amount = "1000"
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
    subscriber_email_addresses = ["ben.reynolds-carr@hackney.gov.uk"]
  }
}