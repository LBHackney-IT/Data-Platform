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
  source                         = "../modules/db-snapshot-to-s3"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_for_api_account.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  service_area                   = "housing"
  rds_instance_ids               = var.rds_instance_ids

  providers = {
    aws = aws.aws_api_account
  }
}
