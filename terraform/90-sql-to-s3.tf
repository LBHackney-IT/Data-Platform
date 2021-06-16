module "liberator_to_parquet" {
  source                     = "../modules/sql-to-parquet"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  instance_name              = lower("${local.identifier_prefix}-liberator-to-parquet")
  watched_bucket_name        = module.liberator_data_storage.bucket_id
  watched_bucket_kms_key_arn = module.liberator_data_storage.kms_key_arn
  aws_subnet_ids             = data.aws_subnet_ids.network.ids
}

module "liberator_db_snapshot_to_s3" {
  source                         = "../modules/db-snapshot-to-s3"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = "${local.identifier_prefix}-dp"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  service_area                   = "parking"
  rds_instance_ids               = [module.liberator_to_parquet.rds_instance_id]
}
