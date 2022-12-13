module "lambda_monitoring_dashboard" {
    count               = local.is_production_environment ? 1 : 0
    source              = "../modules/lambda-monitoring-dashboard"
    tags                = module.tags.values
    identifier_prefix   = local.short_identifier_prefix
}
