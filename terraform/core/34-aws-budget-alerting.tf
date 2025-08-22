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
  name  = "/data-and-insight/budget-alert-recipients"
  type  = "StringList"
  value = "value"
  tags  = module.tags.values
}

data "aws_ssm_parameter" "budget_alert_recipients" {
  name = aws_ssm_parameter.budget_alert_recipients.value
}

module "aws_budget_athena" {
  count  = local.is_live_environment ? 1 : 0
  source = "github.com/LBHackney-IT/ce-aws-budgets-lbh.git?ref=176a7e7234d74d94d5116c7f0b5d59f6e6db0a48" # v1.4.0

  budget_name  = "Athena Daily Budget Alert"
  budget_type  = "COST"
  limit_amount = local.is_production_environment ? "5" : "3"
  time_unit    = "DAILY"

  cost_filter = [
    {
      name   = "Service"
      values = ["Amazon Athena"]
    }
  ]

  comparison_operator        = "GREATER_THAN"
  threshold                  = 100
  threshold_type             = "PERCENTAGE"
  notification_type          = "ACTUAL"
  subscriber_email_addresses = [data.aws_ssm_parameter.budget_alert_recipients.value]

  enable_anomaly_detection       = true
  anomaly_monitor_name           = "AthenaDailyAnomalyMonitor"
  anomaly_monitor_type           = "DIMENSIONAL"
  anomaly_monitor_dimension      = "SERVICE"
  anomaly_subscription_name      = "AthenaDailySubscription"
  anomaly_subscription_frequency = "DAILY"
  threshold_key                  = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
  match_options                  = ["GREATER_THAN_OR_EQUAL"]
  threshold_values               = ["1"]
}

module "aws_budget_glue" {
  count  = local.is_live_environment ? 1 : 0
  source = "github.com/LBHackney-IT/ce-aws-budgets-lbh.git?ref=671dab00698fbef054ebc15b7928e03aae525583"


  budget_name  = "Glue Daily Budget Alert"
  budget_type  = "COST"
  limit_amount = local.is_production_environment ? "45" : "15"
  time_unit    = "DAILY"

  cost_filter = [
    {
      name   = "Service"
      values = ["Amazon Glue"]
    }
  ]

  comparison_operator        = "GREATER_THAN"
  threshold                  = 100
  threshold_type             = "PERCENTAGE"
  notification_type          = "ACTUAL"
  subscriber_email_addresses = [data.aws_ssm_parameter.budget_alert_recipients.value]

  enable_anomaly_detection       = true
  anomaly_monitor_name           = "AthenaDailyAnomalyMonitor"
  anomaly_monitor_type           = "DIMENSIONAL"
  anomaly_monitor_dimension      = "SERVICE"
  anomaly_subscription_name      = "AthenaDailySubscription"
  anomaly_subscription_frequency = "DAILY"
  threshold_key                  = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
  match_options                  = ["GREATER_THAN_OR_EQUAL"]
  threshold_values               = ["1"]
}
