module "ringgo_sftp_ingestion_lambda_alarm" {
    count               = local.is_production_environment ? 1 : 0
    source              = "../modules/lambda-alarms-and-monitoring"
    tags                = module.tags.values
    identifier_prefix   = local.short_identifier_prefix
    lambda_name         = "${local.short_identifier_prefix}sftp-to-s3"
}

module "icaseworks_api_ingestion_lambda_alarm" {
    count               = local.is_production_environment ? 1 : 0
    source              = "../modules/lambda-alarms-and-monitoring"
    tags                = module.tags.values
    identifier_prefix   = local.short_identifier_prefix
    lambda_name         = "${local.short_identifier_prefix}icaseworks-api-ingestion"
}
