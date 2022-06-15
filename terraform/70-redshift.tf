module "redshift" {
  count = local.is_live_environment ? 1 : 0

  source                   = "../modules/redshift"
  tags                     = module.tags.values
  identifier_prefix        = local.identifier_prefix
  subnet_ids_list          = local.subnet_ids_list
  vpc_id                   = data.aws_vpc.network.id
  landing_zone_bucket_arn  = module.landing_zone.bucket_arn
  refined_zone_bucket_arn  = module.refined_zone.bucket_arn
  trusted_zone_bucket_arn  = module.trusted_zone.bucket_arn
  raw_zone_bucket_arn      = module.raw_zone.bucket_arn
  landing_zone_kms_key_arn = module.landing_zone.kms_key_arn
  raw_zone_kms_key_arn     = module.raw_zone.kms_key_arn
  refined_zone_kms_key_arn = module.refined_zone.kms_key_arn
  trusted_zone_kms_key_arn = module.trusted_zone.kms_key_arn
  secrets_manager_key      = aws_kms_key.secrets_manager_key.arn
}

// Configuration of redshift external schemas, users & granting permissions

locals {
  unrestricted_schemas = [
    replace(module.department_unrestricted.trusted_zone_catalog_database_name, "-", "_"),
    replace(module.department_unrestricted.refined_zone_catalog_database_name, "-", "_"),
    replace(module.department_unrestricted.raw_zone_catalog_database_name, "-", "_")
  ]

  redshift_schemas = {
    dataplatform_stg_tascomi_refined_zone = aws_glue_catalog_database.refined_zone_tascomi.name,

    housing_repairs_raw_zone     = module.department_housing_repairs.raw_zone_catalog_database_name,
    housing_repairs_refined_zone = module.department_housing_repairs.refined_zone_catalog_database_name,
    housing_repairs_trusted_zone = module.department_housing_repairs.trusted_zone_catalog_database_name,

    parking_raw_zone_liberator     = aws_glue_catalog_database.raw_zone_liberator.name,
    parking_refined_zone_liberator = aws_glue_catalog_database.refined_zone_liberator.name,

    parking_raw_zone     = module.department_parking.raw_zone_catalog_database_name,
    parking_refined_zone = module.department_parking.refined_zone_catalog_database_name,
    parking_trusted_zone = module.department_parking.trusted_zone_catalog_database_name,

    finance_raw_zone     = module.department_finance.raw_zone_catalog_database_name,
    finance_refined_zone = module.department_finance.refined_zone_catalog_database_name,
    finance_trusted_zone = module.department_finance.trusted_zone_catalog_database_name,

    data_and_insight_raw_zone     = module.department_data_and_insight.raw_zone_catalog_database_name,
    data_and_insight_refined_zone = module.department_data_and_insight.refined_zone_catalog_database_name,
    data_and_insight_trusted_zone = module.department_data_and_insight.trusted_zone_catalog_database_name,

    env_enforcement_raw_zone     = module.department_env_enforcement.raw_zone_catalog_database_name,
    env_enforcement_refined_zone = module.department_env_enforcement.refined_zone_catalog_database_name,
    env_enforcement_trusted_zone = module.department_env_enforcement.trusted_zone_catalog_database_name,

    planning_raw_zone     = module.department_planning.raw_zone_catalog_database_name,
    planning_refined_zone = module.department_planning.refined_zone_catalog_database_name,
    planning_trusted_zone = module.department_planning.trusted_zone_catalog_database_name,

    sandbox_trusted_zone = module.department_sandbox.trusted_zone_catalog_database_name,
    sandbox_refined_zone = module.department_sandbox.refined_zone_catalog_database_name,
    sandbox_raw_zone     = module.department_sandbox.raw_zone_catalog_database_name,

    benefits_and_housing_needs_trusted_zone = module.department_benefits_and_housing_needs.trusted_zone_catalog_database_name,
    benefits_and_housing_needs_refined_zone = module.department_benefits_and_housing_needs.refined_zone_catalog_database_name,
    benefits_and_housing_needs_raw_zone     = module.department_benefits_and_housing_needs.raw_zone_catalog_database_name,

    revenues_trusted_zone = module.department_revenues.trusted_zone_catalog_database_name,
    revenues_refined_zone = module.department_revenues.refined_zone_catalog_database_name,
    revenues_raw_zone     = module.department_revenues.raw_zone_catalog_database_name,

    environmental_services_trusted_zone = module.department_environmental_services.trusted_zone_catalog_database_name,
    environmental_services_refined_zone = module.department_environmental_services.refined_zone_catalog_database_name,
    environmental_services_raw_zone     = module.department_environmental_services.raw_zone_catalog_database_name,

    housing_trusted_zone = module.department_housing.trusted_zone_catalog_database_name,
    housing_refined_zone = module.department_housing.refined_zone_catalog_database_name,
    housing_raw_zone     = module.department_housing.raw_zone_catalog_database_name,
  }

  redshift_users = [
    {
      user_name  = module.department_housing_repairs.identifier_snake_case
      secret_arn = module.department_housing_repairs.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_housing_repairs.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_parking.identifier_snake_case
      secret_arn = module.department_parking.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_parking.raw_zone_catalog_database_name, "-", "_"),
        "parking_raw_zone_liberator",
        replace(module.department_parking.refined_zone_catalog_database_name, "-", "_"),
        "parking_refined_zone_liberator",
        replace(module.department_parking.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_finance.identifier_snake_case
      secret_arn = module.department_finance.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_finance.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_data_and_insight.identifier_snake_case
      secret_arn = module.department_data_and_insight.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(aws_glue_catalog_database.refined_zone_tascomi.name, "-", "_"),

        replace(module.department_housing_repairs.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs.trusted_zone_catalog_database_name, "-", "_"),

        replace(aws_glue_catalog_database.raw_zone_liberator.name, "-", "_"),
        replace(aws_glue_catalog_database.refined_zone_liberator.name, "-", "_"),

        replace(module.department_parking.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_parking.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_parking.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_finance.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_data_and_insight.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_data_and_insight.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_data_and_insight.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_env_enforcement.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_planning.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_sandbox.trusted_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox.raw_zone_catalog_database_name, "-", "_"),

        replace(module.department_benefits_and_housing_needs.trusted_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs.raw_zone_catalog_database_name, "-", "_"),

        replace(module.department_revenues.trusted_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues.raw_zone_catalog_database_name, "-", "_"),

        replace(module.department_environmental_services.trusted_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services.raw_zone_catalog_database_name, "-", "_"),

        replace(module.department_housing.trusted_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing.raw_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_env_enforcement.identifier_snake_case
      secret_arn = module.department_env_enforcement.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_env_enforcement.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_planning.identifier_snake_case
      secret_arn = module.department_planning.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_sandbox.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox.trusted_zone_catalog_database_name, "-", "_"),
        "dataplatform_stg_tascomi_refined_zone"
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_sandbox.identifier_snake_case
      secret_arn = module.department_sandbox.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_sandbox.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_benefits_and_housing_needs.identifier_snake_case
      secret_arn = module.department_benefits_and_housing_needs.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_benefits_and_housing_needs.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_revenues.identifier_snake_case
      secret_arn = module.department_revenues.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_revenues.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_environmental_services.identifier_snake_case
      secret_arn = module.department_environmental_services.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_environmental_services.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_housing.identifier_snake_case
      secret_arn = module.department_housing.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_housing.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    }
  ]
}