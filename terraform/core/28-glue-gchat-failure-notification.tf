locals {
  glue_failure_cloudwatch_event_pattern = {
    "source" : [
      "aws.glue"
    ],
    "detail-type" : [
      "Glue Job State Change"
    ],
    "detail" : {
      "state" : [
        "FAILED",
        "TIMEOUT",
        "ERROR"
      ]
    }
  }
}

module "glue-failure-alert-notifications" {
  count                          = local.is_production_environment ? 1 : 0
  source                         = "../modules/glue-failure-alert-notifications"
  tags                           = module.tags.values
  identifier_prefix              = local.short_identifier_prefix
  lambda_name                    = "glue-failure-gchat-notifications"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  cloudwatch_event_pattern       = jsonencode(local.glue_failure_cloudwatch_event_pattern)

  secret_name             = "${local.short_identifier_prefix}glue-failure-gchat-webhook-url"
  secrets_manager_kms_key = aws_kms_key.secrets_manager_key

  lambda_environment_variables = {
    "SECRET_NAME" = "${local.short_identifier_prefix}glue-failure-gchat-webhook-url"
  }
}
