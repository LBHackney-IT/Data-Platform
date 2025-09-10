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
  additional_iam_roles     = local.is_production_environment ? [] : [aws_iam_role.parking_redshift_copier[0].arn]
}

// Configuration of redshift external schemas, users & granting permissions

locals {
  unrestricted_schemas = [
    replace(module.department_unrestricted_data_source.raw_zone_catalog_database_name, "-", "_"),
    replace(module.department_unrestricted_data_source.refined_zone_catalog_database_name, "-", "_"),
    replace(module.department_unrestricted_data_source.trusted_zone_catalog_database_name, "-", "_")
  ]

  redshift_schemas = {
    replace(aws_glue_catalog_database.refined_zone_tascomi.name, "-", "_") = aws_glue_catalog_database.refined_zone_tascomi.name,
    replace(aws_glue_catalog_database.trusted_zone_tascomi.name, "-", "_") = aws_glue_catalog_database.trusted_zone_tascomi.name,

    replace(module.department_housing_repairs_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_housing_repairs_data_source.raw_zone_catalog_database_name,
    replace(module.department_housing_repairs_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_housing_repairs_data_source.refined_zone_catalog_database_name,
    replace(module.department_housing_repairs_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_housing_repairs_data_source.trusted_zone_catalog_database_name,
    replace(aws_glue_catalog_database.housing_nec_migration_database.name, "-", "_")                    = aws_glue_catalog_database.housing_nec_migration_database.name,

    parking_raw_zone_liberator     = aws_glue_catalog_database.raw_zone_liberator.name,
    parking_refined_zone_liberator = aws_glue_catalog_database.refined_zone_liberator.name,

    # This is to compensate for the liberator schemas names being different from the glue catalog databases
    liberator_raw_zone     = aws_glue_catalog_database.raw_zone_liberator.name,
    liberator_refined_zone = aws_glue_catalog_database.refined_zone_liberator.name,

    replace(module.department_parking_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_parking_data_source.raw_zone_catalog_database_name,
    replace(module.department_parking_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_parking_data_source.refined_zone_catalog_database_name,
    replace(module.department_parking_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_parking_data_source.trusted_zone_catalog_database_name,

    replace(module.department_finance_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_finance_data_source.raw_zone_catalog_database_name,
    replace(module.department_finance_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_finance_data_source.refined_zone_catalog_database_name,
    replace(module.department_finance_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_finance_data_source.trusted_zone_catalog_database_name,

    replace(module.department_data_and_insight_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_data_and_insight_data_source.raw_zone_catalog_database_name,
    replace(module.department_data_and_insight_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_data_and_insight_data_source.refined_zone_catalog_database_name,
    replace(module.department_data_and_insight_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_data_and_insight_data_source.trusted_zone_catalog_database_name,

    replace(module.department_env_enforcement_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_env_enforcement_data_source.raw_zone_catalog_database_name,
    replace(module.department_env_enforcement_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_env_enforcement_data_source.refined_zone_catalog_database_name,
    replace(module.department_env_enforcement_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_env_enforcement_data_source.trusted_zone_catalog_database_name,

    replace(module.department_planning_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_planning_data_source.raw_zone_catalog_database_name,
    replace(module.department_planning_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_planning_data_source.refined_zone_catalog_database_name,
    replace(module.department_planning_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_planning_data_source.trusted_zone_catalog_database_name,

    replace(module.department_sandbox_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_sandbox_data_source.raw_zone_catalog_database_name,
    replace(module.department_sandbox_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_sandbox_data_source.refined_zone_catalog_database_name,
    replace(module.department_sandbox_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_sandbox_data_source.trusted_zone_catalog_database_name,

    replace(module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name,
    replace(module.department_benefits_and_housing_needs_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_benefits_and_housing_needs_data_source.refined_zone_catalog_database_name,
    replace(module.department_benefits_and_housing_needs_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_benefits_and_housing_needs_data_source.trusted_zone_catalog_database_name,

    replace(module.department_revenues_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_revenues_data_source.raw_zone_catalog_database_name,
    replace(module.department_revenues_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_revenues_data_source.refined_zone_catalog_database_name,
    replace(module.department_revenues_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_revenues_data_source.trusted_zone_catalog_database_name,

    replace(module.department_environmental_services_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_environmental_services_data_source.raw_zone_catalog_database_name,
    replace(module.department_environmental_services_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_environmental_services_data_source.refined_zone_catalog_database_name,
    replace(module.department_environmental_services_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_environmental_services_data_source.trusted_zone_catalog_database_name,

    replace(module.department_housing_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_housing_data_source.raw_zone_catalog_database_name,
    replace(module.department_housing_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_housing_data_source.refined_zone_catalog_database_name,
    replace(module.department_housing_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_housing_data_source.trusted_zone_catalog_database_name,

    replace(module.department_unrestricted_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_unrestricted_data_source.raw_zone_catalog_database_name,
    replace(module.department_unrestricted_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_unrestricted_data_source.refined_zone_catalog_database_name,
    replace(module.department_unrestricted_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_unrestricted_data_source.trusted_zone_catalog_database_name

    replace(module.department_children_family_services_data_source.raw_zone_catalog_database_name, "-", "_")     = module.department_children_family_services_data_source.raw_zone_catalog_database_name,
    replace(module.department_children_family_services_data_source.refined_zone_catalog_database_name, "-", "_") = module.department_children_family_services_data_source.refined_zone_catalog_database_name,
    replace(module.department_children_family_services_data_source.trusted_zone_catalog_database_name, "-", "_") = module.department_children_family_services_data_source.trusted_zone_catalog_database_name,

    replace(aws_glue_catalog_database.ctax_raw_zone.name, "-", "_") = aws_glue_catalog_database.ctax_raw_zone.name,
    replace(aws_glue_catalog_database.nndr_raw_zone.name, "-", "_") = aws_glue_catalog_database.nndr_raw_zone.name,
    replace(aws_glue_catalog_database.hben_raw_zone.name, "-", "_") = aws_glue_catalog_database.hben_raw_zone.name
  }

  redshift_users = [
    {
      user_name  = module.department_housing_repairs_data_source.identifier_snake_case
      secret_arn = module.department_housing_repairs_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_housing_repairs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.trusted_zone_catalog_database_name, "-", "_"),
        replace(aws_glue_catalog_database.housing_nec_migration_database.name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_parking_data_source.identifier_snake_case
      secret_arn = module.department_parking_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_parking_data_source.raw_zone_catalog_database_name, "-", "_"),
        "parking_raw_zone_liberator",
        "liberator_raw_zone",
        replace(module.department_parking_data_source.refined_zone_catalog_database_name, "-", "_"),
        "parking_refined_zone_liberator",
        "liberator_refined_zone",
        replace(module.department_parking_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_finance_data_source.identifier_snake_case
      secret_arn = module.department_finance_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_finance_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_data_and_insight_data_source.identifier_snake_case
      secret_arn = module.department_data_and_insight_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(aws_glue_catalog_database.refined_zone_tascomi.name, "-", "_"),
        replace(aws_glue_catalog_database.trusted_zone_tascomi.name, "-", "_"),

        replace(module.department_housing_repairs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.trusted_zone_catalog_database_name, "-", "_"),

        "parking_raw_zone_liberator",
        "parking_refined_zone_liberator",

        replace(module.department_parking_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_parking_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_parking_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_finance_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_data_and_insight_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_data_and_insight_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_data_and_insight_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_env_enforcement_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_planning_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_sandbox_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_revenues_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_environmental_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_housing_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_children_family_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(aws_glue_catalog_database.ctax_raw_zone.name, "-", "_"),
        replace(aws_glue_catalog_database.nndr_raw_zone.name, "-", "_"),
        replace(aws_glue_catalog_database.hben_raw_zone.name, "-", "_"),

      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_env_enforcement_data_source.identifier_snake_case
      secret_arn = module.department_env_enforcement_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_env_enforcement_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_planning_data_source.identifier_snake_case
      secret_arn = module.department_planning_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_planning_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.trusted_zone_catalog_database_name, "-", "_"),
        "dataplatform_stg_tascomi_refined_zone"
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_sandbox_data_source.identifier_snake_case
      secret_arn = module.department_sandbox_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_sandbox_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_benefits_and_housing_needs_data_source.identifier_snake_case
      secret_arn = module.department_benefits_and_housing_needs_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_revenues_data_source.identifier_snake_case
      secret_arn = module.department_revenues_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_revenues_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_environmental_services_data_source.identifier_snake_case
      secret_arn = module.department_environmental_services_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_environmental_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_housing_data_source.identifier_snake_case
      secret_arn = module.department_housing_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_housing_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    },
    {
      user_name  = module.department_children_family_services_data_source.identifier_snake_case
      secret_arn = module.department_children_family_services_data_source.redshift_cluster_secret
      schemas_to_grant_access_to = concat([
        replace(module.department_children_family_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ], local.unrestricted_schemas)
    }
  ]
  unrestricted_data_role_name = "public_ro"

  redshift_roles = [
    {
      role_name                  = local.unrestricted_data_role_name
      schemas_to_grant_access_to = local.unrestricted_schemas
    },
    {
      role_name = "${module.department_housing_repairs_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_housing_repairs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_parking_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_parking_data_source.raw_zone_catalog_database_name, "-", "_"),
        "parking_raw_zone_liberator",
        "liberator_raw_zone",
        replace(module.department_parking_data_source.refined_zone_catalog_database_name, "-", "_"),
        "parking_refined_zone_liberator",
        "liberator_refined_zone",
        replace(module.department_parking_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_finance_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_finance_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_data_and_insight_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_housing_repairs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_repairs_data_source.trusted_zone_catalog_database_name, "-", "_"),

        "parking_raw_zone_liberator",
        "parking_refined_zone_liberator",

        replace(module.department_parking_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_parking_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_parking_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_finance_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_finance_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_data_and_insight_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_data_and_insight_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_data_and_insight_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_env_enforcement_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_planning_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_sandbox_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_revenues_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_environmental_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_housing_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(module.department_children_family_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.trusted_zone_catalog_database_name, "-", "_"),

        replace(aws_glue_catalog_database.ctax_raw_zone.name, "-", "_"),
        replace(aws_glue_catalog_database.nndr_raw_zone.name, "-", "_"),
        replace(aws_glue_catalog_database.hben_raw_zone.name, "-", "_")

      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name,
        "${module.department_housing_repairs_data_source.identifier_snake_case}_ro",
        "${module.department_parking_data_source.identifier_snake_case}_ro",
        "${module.department_finance_data_source.identifier_snake_case}_ro",
        "${module.department_env_enforcement_data_source.identifier_snake_case}_ro",
        "${module.department_planning_data_source.identifier_snake_case}_ro",
        "${module.department_sandbox_data_source.identifier_snake_case}_ro",
        "${module.department_benefits_and_housing_needs_data_source.identifier_snake_case}_ro",
        "${module.department_revenues_data_source.identifier_snake_case}_ro",
        "${module.department_environmental_services_data_source.identifier_snake_case}_ro",
        "${module.department_housing_data_source.identifier_snake_case}_ro",
        "${module.department_children_family_services_data_source.identifier_snake_case}_ro"
      ]
    },
    {
      role_name = "${module.department_env_enforcement_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_env_enforcement_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_env_enforcement_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_planning_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_planning_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_planning_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_sandbox_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_sandbox_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_sandbox_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_benefits_and_housing_needs_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_benefits_and_housing_needs_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_benefits_and_housing_needs_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_revenues_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_revenues_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_revenues_data_source.trusted_zone_catalog_database_name, "-", "_")
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_environmental_services_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_environmental_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_environmental_services_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_housing_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_housing_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_housing_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    },
    {
      role_name = "${module.department_children_family_services_data_source.identifier_snake_case}_ro"
      schemas_to_grant_access_to = [
        replace(module.department_children_family_services_data_source.raw_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.refined_zone_catalog_database_name, "-", "_"),
        replace(module.department_children_family_services_data_source.trusted_zone_catalog_database_name, "-", "_"),
      ]
      roles_to_inherit_permissions_from = [
        local.unrestricted_data_role_name
      ]
    }
  ]
}
