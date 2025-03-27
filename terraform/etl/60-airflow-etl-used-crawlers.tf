# mosaic ETL resources

resource "aws_glue_crawler" "mosaic_raw_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "${local.short_identifier_prefix}${module.department_children_family_services_data_source.identifier}-mosaic-raw-zone"
  role          = module.department_children_family_services_data_source.glue_role_arn
  database_name = module.department_children_family_services_data_source.raw_zone_catalog_database_name

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/${module.department_children_family_services_data_source.identifier}/mosaic/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

}

resource "aws_glue_crawler" "allocations_refined_tables" {
  count         = local.is_live_environment ? 1 : 0
  name          = "${local.short_identifier_prefix}${module.department_children_family_services_data_source.identifier}-allocations-refined-tables"
  role          = module.department_children_family_services_data_source.glue_role_arn
  database_name = module.department_children_family_services_data_source.refined_zone_catalog_database_name

  s3_target {
    path = "s3://${module.refined_zone_data_source.bucket_id}/${module.department_children_family_services_data_source.identifier}/mosaic/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

}

resource "aws_glue_crawler" "mosaic_raw_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "${local.short_identifier_prefix}${module.department_children_family_services_data_source.identifier}-synergy-raw-zone"
  role          = module.department_children_family_services_data_source.glue_role_arn
  database_name = module.department_children_family_services_data_source.raw_zone_catalog_database_name

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/${module.department_children_family_services_data_source.identifier}/synergy/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })

}

resource "aws_glue_crawler" "streetscene_street_systems_raw_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "${local.short_identifier_prefix}Streetscene Traffic Counters Raw Zone"
  role          = data.aws_iam_role.glue_role.arn
  database_name = "streetscene-raw-zone"

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/streetscene/traffic-counters/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })
}

resource "aws_glue_crawler" "parking_spatially_enriched_refined_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "${local.short_identifier_prefix}Parking Spatially Enriched Refined Zone"
  role          = data.aws_iam_role.glue_role.arn
  database_name = module.department_parking_data_source.refined_zone_catalog_database_name

  s3_target {
    path = "s3://${module.refined_zone_data_source.bucket_id}/parking/spatially-enriched/"
  }
  table_prefix = "spatially_enriched_"
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })
}

locals {
  departments = {
    parking            = module.department_parking_data_source
    housing            = module.department_housing_data_source
    data_and_insight   = module.department_data_and_insight_data_source
    child_fam_services = module.department_children_family_services_data_source
    unrestricted       = module.department_unrestricted_data_source
    env_services       = module.department_environmental_services_data_source
  }
}

resource "aws_glue_crawler" "google_sheet_ingestion_raw_zone" {
  for_each      = local.is_live_environment ? local.departments : {}
  name          = "${local.short_identifier_prefix}${each.value.identifier}-google-sheet-ingestion-raw-zone"
  role          = data.aws_iam_role.glue_role.arn
  database_name = each.value.raw_zone_catalog_database_name

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/${each.value.identifier}/google-sheets/"
  }

  table_prefix = "${each.value.identifier_snake_case}_"

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
      TableGroupingPolicy     = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      Tables     = { AddOrUpdateBehavior = "MergeNewColumns" }
    }
  })
}
