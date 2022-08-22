
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
  count                      = 1
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
  aws_subnet_ids             = data.aws_subnet_ids.network.ids
  ecs_cluster_arn            = aws_ecs_cluster.workers.arn
}

module "liberator_db_snapshot_to_s3" {
  count                          = 1
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
  backdated_workflow_name        = aws_glue_workflow.parking_liberator_backdated_data.name
  backdated_workflow_arn         = aws_glue_workflow.parking_liberator_backdated_data.arn
}

resource "aws_glue_workflow" "parking_liberator_data" {
  # This resource is modified outside of terraform by parking analysts.
  # Any change which forces the workflow to be recreated will lose their changes.
  name = "${local.short_identifier_prefix}parking-liberator-data-workflow"
  tags = module.tags.values
}

resource "aws_glue_workflow" "parking_liberator_backdated_data" {
  name = "${local.short_identifier_prefix}parking-liberator-backdated-data-workflow"
  tags = module.tags.values

  lifecycle {
    ignore_changes = ["default_run_properties"]
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