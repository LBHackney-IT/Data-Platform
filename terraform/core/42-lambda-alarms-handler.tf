locals {
    lambda_alarms_handler_secret_name = "${local.short_identifier_prefix}lambda-alarms-handler-secret"
}

module "lambda_alarms_handler" {
    count                           = local.is_production_environment ? 1 : 0
    source                          = "../modules/lambda-alarms-handler"
    tags                            = module.tags.values
    identifier_prefix               = local.short_identifier_prefix
    lambda_name                     = "lambda-alarms-handler"    
    lambda_artefact_storage_bucket  = module.lambda_artefact_storage.bucket_id

    secret_name                     = local.lambda_alarms_handler_secret_name
    secrets_manager_kms_key         = aws_kms_key.secrets_manager_key

    lambda_environment_variables    = {
        "SECRET_NAME"               = local.lambda_alarms_handler_secret_name
    }
}
