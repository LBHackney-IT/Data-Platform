module "copy_from_s3_to_s3" {
  source = "../modules/copy-from-s3-to-s3"
  tags   = module.tags.values

  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage
  origin_bucket                  = module.landing_zone
  origin_path                    = "/housing/rentsense"
  target_bucket = {
    bucket_id   = "dataplatform-joates-test"
    bucket_arn  = "arn:aws:s3:::dataplatform-joates-test"
    kms_key_id  = "874631b2-909c-4268-99f7-8fbdda42178f"
    kms_key_arn = "arn:aws:kms:eu-west-2:937934410339:key/874631b2-909c-4268-99f7-8fbdda42178f"
  }
  target_path = "/path/to/files"
}