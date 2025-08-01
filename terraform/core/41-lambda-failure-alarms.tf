module "ringgo_sftp_ingestion_lambda_alarm" {
  count                      = local.is_production_environment ? 1 : 0
  source                     = "../modules/lambda-alarms-and-monitoring"
  tags                       = module.tags.values
  identifier_prefix          = local.short_identifier_prefix
  lambda_name                = "${local.short_identifier_prefix}sftp-to-s3"
  project                    = var.project
  environment                = var.environment
  alarms_handler_lambda_name = module.lambda_alarms_handler[0].lambda_name
  alarms_handler_lambda_arn  = module.lambda_alarms_handler[0].lambda_arn
}

module "icaseworks_api_ingestion_lambda_alarm" {
  count                      = local.is_production_environment ? 1 : 0
  source                     = "../modules/lambda-alarms-and-monitoring"
  tags                       = module.tags.values
  identifier_prefix          = local.short_identifier_prefix
  lambda_name                = "${local.short_identifier_prefix}icaseworks-api-ingestion"
  project                    = var.project
  environment                = var.environment
  alarms_handler_lambda_name = module.lambda_alarms_handler[0].lambda_name
  alarms_handler_lambda_arn  = module.lambda_alarms_handler[0].lambda_arn
}


module "rds_snapshot_s3_to_s3_copie_lambda_alarm" {
  count                      = local.is_production_environment ? 1 : 0
  source                     = "../modules/lambda-alarms-and-monitoring"
  tags                       = module.tags.values
  identifier_prefix          = local.short_identifier_prefix
  lambda_name                = module.liberator_rds_snapshot_to_s3[0].rds_snapshot_s3_to_s3_copier_lambda_name
  project                    = var.project
  environment                = var.environment
  alarms_handler_lambda_name = module.lambda_alarms_handler[0].lambda_name
  alarms_handler_lambda_arn  = module.lambda_alarms_handler[0].lambda_arn
}

module "export_rds_to_s3_snapshot_lambda_alarm" {
  count                      = local.is_production_environment ? 1 : 0
  source                     = "../modules/lambda-alarms-and-monitoring"
  tags                       = module.tags.values
  identifier_prefix          = local.short_identifier_prefix
  lambda_name                = module.liberator_rds_snapshot_to_s3[0].export_rds_to_s3_snapshot_lambda_name
  project                    = var.project
  environment                = var.environment
  alarms_handler_lambda_name = module.lambda_alarms_handler[0].lambda_name
  alarms_handler_lambda_arn  = module.lambda_alarms_handler[0].lambda_arn
}
