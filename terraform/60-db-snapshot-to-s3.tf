//resource "aws_s3_bucket" "lambda_artefact_storage" {
//  provider = aws.aws_api_account
//  tags     = module.tags.values
//
//  bucket        = lower("${local.identifier_prefix}-lambda-artefact-storage")
//  acl           = "private"
//  force_destroy = true
//}

# module "db_snapshot_to_s3" {
#   source                         = "../modules/db-snapshot-to-s3"
#   tags                           = module.tags.values
#   project                        = var.project
#   environment                    = var.environment
#   identifier_prefix              = local.identifier_prefix
#   lambda_artefact_storage_bucket = aws_s3_bucket.lambda_artefact_storage.bucket
#   landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
#   landing_zone_bucket_arn        = module.landing_zone.bucket_arn
#   landing_zone_bucket_id         = module.landing_zone.bucket_id
#   rds_instance_ids               = var.rds_instance_ids

#   providers = {
#     aws = aws.aws_api_account
#   }
# }
