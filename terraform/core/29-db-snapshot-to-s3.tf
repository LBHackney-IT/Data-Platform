module "lambda_artefact_storage_for_api_account" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Lambda Artefact Storage"
  bucket_identifier = "api-lambda-artefact-storage"

  providers = {
    aws = aws.aws_api_account
  }
}

module "db_snapshot_to_s3" {
  count                          = local.is_production_environment ? 1 : 0
  source                         = "../modules/db-snapshot-to-s3"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_for_api_account.bucket_id
  zone_kms_key_arn               = module.raw_zone.kms_key_arn
  zone_bucket_arn                = module.raw_zone.bucket_arn
  zone_bucket_id                 = module.raw_zone.bucket_id
  rds_export_storage_bucket_arn  = module.rds_export_storage.bucket_arn
  rds_export_storage_bucket_id   = module.rds_export_storage.bucket_id
  rds_export_storage_kms_key_arn = module.rds_export_storage.kms_key_arn
  rds_export_storage_kms_key_id  = module.rds_export_storage.kms_key_id
  service_area                   = "unrestricted"
  rds_instance_ids               = var.rds_instance_ids

  providers = {
    aws = aws.aws_api_account
  }
}

moved {
  from = module.db_snapshot_to_s3.module.rds_export_storage.aws_s3_bucket.bucket
  to   = module.db_snapshot_to_s3[0].module.rds_export_storage.aws_s3_bucket.bucket
}

moved {
  from = module.db_snapshot_to_s3[0].module.rds_export_storage.aws_s3_bucket.bucket
  to   = module.addresses_api_rds_export_storage.aws_s3_bucket.bucket
}
