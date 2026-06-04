locals {
  governance_department_data_sources = [
    module.department_housing_repairs_data_source,
    module.department_parking_data_source,
    module.department_finance_data_source,
    module.department_data_and_insight_data_source,
    module.department_env_enforcement_data_source,
    module.department_planning_data_source,
    module.department_unrestricted_data_source,
    module.department_sandbox_data_source,
    module.department_benefits_and_housing_needs_data_source,
    module.department_revenues_data_source,
    module.department_environmental_services_data_source,
    module.department_housing_data_source,
    module.department_customer_services_data_source,
    module.department_hr_and_od_data_source,
    module.department_children_family_services_data_source,
  ]

  governance_department_glue_database_names = flatten([
    for department in local.governance_department_data_sources : [
      department.raw_zone_catalog_database_name,
      department.refined_zone_catalog_database_name,
      department.trusted_zone_catalog_database_name,
    ]
  ])

  governance_etl_glue_database_names = concat(
    [
      aws_glue_catalog_database.raw_zone_unrestricted_address_api.name,
      aws_glue_catalog_database.landing_zone_liberator.name,
      aws_glue_catalog_database.raw_zone_liberator.name,
      aws_glue_catalog_database.refined_zone_liberator.name,
      aws_glue_catalog_database.hackney_synergy_live.name,
      aws_glue_catalog_database.hackney_casemanagement_live.name,
      aws_glue_catalog_database.child_edu_refined.name,
      aws_glue_catalog_database.housing_nec_migration_database.name,
      aws_glue_catalog_database.housing_nec_migration_live_database.name,
      aws_glue_catalog_database.housing_nec_migration_outputs_database.name,
      aws_glue_catalog_database.housing_nec_migration_data_quality.name,
      aws_glue_catalog_database.ctax_raw_zone.name,
      aws_glue_catalog_database.nndr_raw_zone.name,
      aws_glue_catalog_database.hben_raw_zone.name,
      aws_glue_catalog_database.metastore.name,
      aws_glue_catalog_database.housing_service_requests_ieg4.name,
      aws_glue_catalog_database.arcus_archive.name,
      aws_glue_catalog_database.raw_zone_tascomi.name,
      aws_glue_catalog_database.refined_zone_tascomi.name,
      aws_glue_catalog_database.trusted_zone_tascomi.name,
      "${local.identifier_prefix}-landing-zone-database",
      "${local.short_identifier_prefix}parking-ringgo-sftp-raw-zone",
    ],
    values(aws_glue_catalog_database.housing_nec_migration_partition_databases)[*].name,
    values(aws_glue_catalog_database.housing_nec_migration_output_databases)[*].name,
    values(aws_glue_catalog_database.department_user_uploads)[*].name,
  )

  governance_glue_database_names = distinct(concat(
    local.governance_department_glue_database_names,
    local.governance_etl_glue_database_names,
  ))
}

resource "aws_lakeformation_permissions" "governance_database_describe" {
  for_each = local.is_production_environment ? nonsensitive(toset(local.governance_glue_database_names)) : toset([])

  principal                     = var.governance_production_account_id
  permissions                   = ["DESCRIBE"]
  permissions_with_grant_option = ["DESCRIBE"]

  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "governance_table_describe_select" {
  for_each = local.is_production_environment ? nonsensitive(toset(local.governance_glue_database_names)) : toset([])

  depends_on = [aws_lakeformation_permissions.governance_database_describe]

  principal                     = var.governance_production_account_id
  permissions                   = ["DESCRIBE", "SELECT"]
  permissions_with_grant_option = ["DESCRIBE", "SELECT"]

  table {
    database_name = each.value
    wildcard      = true
  }
}
