module "mtfh_export_lambda_lambda_alarm" {
  count                      = local.is_production_environment ? 1 : 0
  source                     = "../modules/lambda-alarms-and-monitoring"
  tags                       = module.tags.values
  identifier_prefix          = local.short_identifier_prefix
  lambda_name                = module.export-mtfh-pitr[0].lambda_function_name
  project                    = var.project
  environment                = var.environment
  alarms_handler_lambda_name = module.lambda_alarms_handler[0].lambda_name
  alarms_handler_lambda_arn  = module.lambda_alarms_handler[0].lambda_arn
}