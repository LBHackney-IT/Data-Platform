resource "aws_budgets_budget" "cost" {
    name = "all-cost-budget"
    budget_type = "COST"
    limit_amount = "10"
    limit_unit = "GBP"
    time_unit = "DAILY"

    notification {
        comparison_operator = "GREATER_THAN"
        threshold = "10"
        threshold_type = "PERCENTAGE"
        notification_type = "FORECASTED"
        subscriber_email_addresses = ["ben.reynolds-carr@hackney.gov.uk"]
    }

    notification {
        comparison_operator = "GREATER_THAN"
        threshold = "100"
        threshold_type = "PERCENTAGE"
        notification_type = "ACTUAL"
        subscriber_email_addresses = ["ben.reynolds-carr@hackney.gov.uk"]
    }    
}