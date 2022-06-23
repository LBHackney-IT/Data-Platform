module "redshift" {
  count = local.is_live_environment ? 1 : 0

  source                   = "../modules/redshift"
  tags                     = module.tags.values
  identifier_prefix        = local.identifier_prefix
  subnet_ids_list          = local.subnet_ids_list
  vpc_id                   = data.aws_vpc.network.id
  landing_zone_bucket_arn  = module.landing_zone_data_source.bucket_arn
  refined_zone_bucket_arn  = module.refined_zone_data_source.bucket_arn
  trusted_zone_bucket_arn  = module.trusted_zone_data_source.bucket_arn
  raw_zone_bucket_arn      = module.raw_zone_data_source.bucket_arn
  landing_zone_kms_key_arn = module.landing_zone_data_source.kms_key_arn
  raw_zone_kms_key_arn     = module.raw_zone_data_source.kms_key_arn
  refined_zone_kms_key_arn = module.refined_zone_data_source.kms_key_arn
  trusted_zone_kms_key_arn = module.trusted_zone_data_source.kms_key_arn
  secrets_manager_key      = data.aws_kms_key.secrets_manager_key.arn
}

// Configuration of redshift external schemas, users & granting permissions

locals {
  unrestricted_schemas = [
    "unrestricted_trusted_zone",
    "unrestricted_refined_zone",
    "unrestricted_raw_zone"
  ]

  redshift_schemas = {
    unrestricted_trusted_zone = module.department_unrestricted_data_source.trusted_zone_catalog_database_name,
    unrestricted_refined_zone = module.department_unrestricted_data_source.refined_zone_catalog_database_name,
    unrestricted_raw_zone     = module.department_unrestricted_data_source.raw_zone_catalog_database_name,

    dataplatform_stg_tascomi_refined_zone = aws_glue_catalog_database.refined_zone_tascomi.name
    planning_refined_zone                 = module.department_planning_data_source.refined_zone_catalog_database_name

    housing_repairs_refined_zone = module.department_housing_repairs_data_source.refined_zone_catalog_database_name
    housing_repairs_raw_zone     = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
    housing_repairs_trusted_zone = module.department_housing_repairs_data_source.trusted_zone_catalog_database_name

    parking_raw_zone_liberator     = "${local.identifier_prefix}-liberator-raw-zone"
    parking_refined_zone_liberator = "${local.identifier_prefix}-liberator-refined-zone"

    parking_raw_zone     = module.department_parking_data_source.raw_zone_catalog_database_name
    parking_refined_zone = module.department_parking_data_source.refined_zone_catalog_database_name
    parking_trusted_zone = module.department_parking_data_source.trusted_zone_catalog_database_name
  }

  redshift_users = [
    {
      user_name  = module.department_parking_data_source.identifier_snake_case
      secret_arn = module.department_parking_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        "parking_refined_zone_liberator",
        "parking_raw_zone_liberator",
        "parking_raw_zone",
        "parking_refined_zone",
        "parking_trusted_zone",

      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_planning_data_source.identifier_snake_case
      secret_arn = module.department_planning_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        "planning_refined_zone",
        "dataplatform_stg_tascomi_refined_zone"
      ], local.unrestricted_schemas)
    },
    {
      user_name                  = module.department_data_and_insight_data_source.identifier_snake_case
      secret_arn                 = module.department_data_and_insight_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_housing_repairs_data_source.identifier_snake_case
      secret_arn = module.department_housing_repairs_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        "housing_repairs_raw_zone",
        "housing_repairs_trusted_zone",
        "housing_repairs_refined_zone"
      ], local.unrestricted_schemas)
    }
  ]
}