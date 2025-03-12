
module "liberator_data_storage" {
  source                     = "../modules/s3-bucket"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  bucket_name                = "Liberator Data Storage"
  bucket_identifier          = "liberator-data-storage"
  include_backup_policy_tags = false
}

module "liberator_dump_to_rds_snapshot" {
  count                      = local.is_live_environment ? 1 : 0
  source                     = "../modules/sql-to-rds-snapshot"
  tags                       = module.tags.values
  project                    = var.project
  environment                = var.environment
  identifier_prefix          = local.identifier_prefix
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  instance_name              = "${local.short_identifier_prefix}liberator-to-rds-snapshot"
  watched_bucket_name        = module.liberator_data_storage.bucket_id
  watched_bucket_kms_key_arn = module.liberator_data_storage.kms_key_arn
  aws_subnet_ids             = data.aws_subnets.network.ids
  ecs_cluster_arn            = aws_ecs_cluster.workers.arn
  vpc_id                     = data.aws_vpc.network.id
}

resource "aws_glue_workflow" "parking_liberator_data" {
  # Components for this workflow are managed mainly in etl/38-aws-glue-job-parking.tf by parking officers
  # There are couple of other resources that are part of the ingestion process, but the core ETL configuration is in the file mentioned above
  name = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  tags = module.tags.values
}

resource "aws_glue_workflow" "parking_liberator_backdated_data" {
  name = "${local.short_identifier_prefix}parking-liberator-backdated-data-workflow"
  tags = module.tags.values

  lifecycle {
    ignore_changes = [default_run_properties]
  }
}

# Lambda execution role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

module "liberator_rds_snapshot_to_s3" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/rds-snapshot-to-s3"
  tags                           = module.tags.values
  identifier_prefix              = local.identifier_prefix
  project                        = var.project
  environment                    = var.environment
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  rds_export_bucket_arn          = module.rds_export_storage.bucket_arn
  rds_export_bucket_id           = module.rds_export_storage.bucket_id
  rds_export_storage_kms_key_arn = module.rds_export_storage.kms_key_arn
  rds_export_storage_kms_key_id  = module.rds_export_storage.kms_key_id
  target_bucket_arn              = module.landing_zone.bucket_arn
  target_bucket_id               = module.landing_zone.bucket_id
  target_bucket_kms_key_arn      = module.landing_zone.kms_key_arn
  target_bucket_kms_key_id       = module.landing_zone.kms_key_id
  target_prefix                  = "parking"
  service_area                   = "parking"
  rds_instance_ids               = [for item in module.liberator_dump_to_rds_snapshot : item.rds_instance_id]
  rds_instance_arns              = [for item in module.liberator_dump_to_rds_snapshot : item.rds_instance_arn]
  workflow_name                  = aws_glue_workflow.parking_liberator_data.name
  workflow_arn                   = aws_glue_workflow.parking_liberator_data.arn
  backdated_workflow_name        = aws_glue_workflow.parking_liberator_backdated_data.name
  backdated_workflow_arn         = aws_glue_workflow.parking_liberator_backdated_data.arn
}

moved {
  from = module.liberator_db_snapshot_to_s3[0].module.rds_export_storage.aws_s3_bucket.bucket
  to   = module.deprecated_rds_export_storage.aws_s3_bucket.bucket
}
