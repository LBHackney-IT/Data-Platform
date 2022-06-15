module "copy_from_s3_to_s3" {
  source = "../modules/copy-from-s3-to-s3"
  tags   = module.tags.values

  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage
  origin_bucket                  = module.trusted_zone
  origin_path                    = "/housing/rentsense"
  target_bucket_arn              = "a random bucket"
  target_path                    = "/path/to/files"
}