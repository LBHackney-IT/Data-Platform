module "department_housing_repairs" {
  source                 = "../modules/department"
  tags                   = module.tags.values
  identifier_prefix      = local.short_identifier_prefix
  identifier             = "housing-repairs"
  landing_zone_bucket_id = module.landing_zone.bucket_id
  raw_zone_bucket_id     = module.raw_zone.bucket_id
  refined_zone_bucket_id = module.refined_zone.bucket_id
  trusted_zone_bucket_id = module.trusted_zone.bucket_id
}

module "department_parking" {
  source                 = "../modules/department"
  tags                   = module.tags.values
  identifier_prefix      = local.short_identifier_prefix
  identifier             = "parking"
  landing_zone_bucket_id = module.landing_zone.bucket_id
  raw_zone_bucket_id     = module.raw_zone.bucket_id
  refined_zone_bucket_id = module.refined_zone.bucket_id
  trusted_zone_bucket_id = module.trusted_zone.bucket_id
}

module "department_finance" {
  source                 = "../modules/department"
  tags                   = module.tags.values
  identifier_prefix      = local.short_identifier_prefix
  identifier             = "finance"
  landing_zone_bucket_id = module.landing_zone.bucket_id
  raw_zone_bucket_id     = module.raw_zone.bucket_id
  refined_zone_bucket_id = module.refined_zone.bucket_id
  trusted_zone_bucket_id = module.trusted_zone.bucket_id
}

module "department_data_and_insight" {
  source                 = "../modules/department"
  tags                   = module.tags.values
  identifier_prefix      = local.short_identifier_prefix
  identifier             = "data_and_insight"
  landing_zone_bucket_id = module.landing_zone.bucket_id
  raw_zone_bucket_id     = module.raw_zone.bucket_id
  refined_zone_bucket_id = module.refined_zone.bucket_id
  trusted_zone_bucket_id = module.trusted_zone.bucket_id
}