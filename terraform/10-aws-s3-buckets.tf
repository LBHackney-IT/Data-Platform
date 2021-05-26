module "landing_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Landing Zone"
  bucket_identifier              = "landing-zone"
//  role_arns_to_share_access_with = [
//    module.db_snapshot_to_s3.s3_to_s3_copier_lambda_role_arn
//  ]
}

module "raw_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Raw Zone"
  bucket_identifier              = "raw-zone"
}

module "refined_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Refined Zone"
  bucket_identifier              = "refined-zone"
}

module "trusted_zone" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Trusted Zone"
  bucket_identifier              = "trusted-zone"
}

module "glue_scripts" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Glue Scripts"
  bucket_identifier              = "glue-scripts"
}

module "glue_temp_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Glue Temp Storage"
  bucket_identifier              = "glue-temp-storage"
}

module "athena_storage" {
  source                         = "../modules/s3-bucket"
  tags                           = module.tags.values
  project                        = var.project
  environment                    = var.environment
  identifier_prefix              = local.identifier_prefix
  bucket_name                    = "Athena Storage"
  bucket_identifier              = "athena-storage"
}
