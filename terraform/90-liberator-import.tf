
module "liberator_data_storage" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Liberator Data Storage"
  bucket_identifier = "liberator-data-storage"
}

module "liberator_dump_to_rds_snapshot" {
  count = local.is_live_environment ? 1 : 0

  source                     = "../modules/sql-to-rds-snapshot"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  is_live_environment        = local.is_live_environment
  instance_name              = lower("${local.identifier_prefix}-liberator-to-rds-snapshot")
  watched_bucket_name        = module.liberator_data_storage.bucket_id
  watched_bucket_kms_key_arn = module.liberator_data_storage.kms_key_arn
  aws_subnet_ids             = data.aws_subnet_ids.network.ids
}

module "liberator_db_snapshot_to_s3" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/db-snapshot-to-s3"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = "${local.identifier_prefix}-dp"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  zone_kms_key_arn               = module.landing_zone.kms_key_arn
  zone_bucket_arn                = module.landing_zone.bucket_arn
  zone_bucket_id                 = module.landing_zone.bucket_id
  service_area                   = "parking"
  rds_instance_ids               = [for item in module.liberator_dump_to_rds_snapshot : item.rds_instance_id]
  workflow_name                  = aws_glue_workflow.parking_liberator_data.name
  workflow_arn                   = aws_glue_workflow.parking_liberator_data.arn
}
