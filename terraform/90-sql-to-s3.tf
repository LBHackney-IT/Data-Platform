module "liberator_bucket" {
  source            = "../modules/s3-bucket"
  tags              = module.tags.values
  project           = var.project
  environment       = var.environment
  identifier_prefix = local.identifier_prefix
  bucket_name       = "Liberator Zone"
  bucket_identifier = "liberator-bucket"
}

module "liberator_to_parquet" {
  source              = "../modules/sql-to-parquet"
  tags                = module.tags.values
  project             = var.project
  environment         = var.environment
  identifier_prefix   = local.identifier_prefix
  instance_name       = lower("${local.identifier_prefix}-liberator-to-parquet")
  watched_bucket_name = module.liberator_bucket.bucket_id
  aws_subnet_ids      = data.aws_subnet_ids.network.ids
  deployment_user_arn = var.deployment_user_arn
}

// TODO: Understand if this is a generic docker image for all jobs like this, or specific to
// the data source.
output "ecr_repository_worker_endpoint" {
  value = module.liberator_to_parquet.ecr_repository_worker_endpoint
}
