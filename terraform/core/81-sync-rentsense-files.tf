module "copy_from_s3_to_s3" {
  source = "../modules/copy-from-s3-to-s3"
  tags   = module.tags.values

  identifier_prefix              = local.identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage
  origin_bucket                  = module.landing_zone
  origin_path                    = "housing/rentsense"
  target_bucket = {
    bucket_id   = "feeds-pluto-mobysoft"
    bucket_arn  = "arn:aws:s3:::feeds-pluto-mobysoft"
    kms_key_id  = null //"874631b2-909c-4268-99f7-8fbdda42178f"
    kms_key_arn = null //"arn:aws:kms:eu-west-2:937934410339:key/874631b2-909c-4268-99f7-8fbdda42178f"
  }
  target_path = "hackneylondonborough.beta/"
  assume_role = "arn:aws:iam::971933469343:role/customer-midas-roles-pluto-HackneyMidasRole-1M6PTJ5VS8104"
}