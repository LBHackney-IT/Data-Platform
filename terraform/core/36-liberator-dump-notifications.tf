module "liberator_dump_notification_emails" {
  count                          = local.is_production_environment ? 1 : 0
  source                         = "../modules/s3-bucket-notification-emails"
  name                           = "${local.short_identifier_prefix}liberator-dump-upload-notification"
  bucket_id                      = module.liberator_data_storage.bucket_id
  bucket_arn                     = module.liberator_data_storage.bucket_arn
  email_list                     = "tim.burke@hackney.gov.uk"
  filter_prefix                  = "parking/"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
}
