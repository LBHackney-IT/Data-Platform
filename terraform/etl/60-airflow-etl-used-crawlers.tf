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
  tags = module.tags.values
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
  tags = module.tags.values
}

resource "aws_glue_crawler" "hackney_synergy_live" {
  count         = local.is_live_environment ? 1 : 0
  name          = "hackney_synergy_live_crawler"
  role          = module.department_children_family_services_data_source.glue_role_arn
  database_name = aws_glue_catalog_database.hackney_synergy_live.name

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/${module.department_children_family_services_data_source.identifier}/synergy/Hackney_Synergy_Live"
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
  tags = module.tags.values
}


resource "aws_glue_crawler" "hackney_casemanagement_live" {
  count         = local.is_live_environment ? 1 : 0
  name          = "hackney_casemanagement_live_crawler"
  role          = module.department_children_family_services_data_source.glue_role_arn
  database_name = aws_glue_catalog_database.hackney_casemanagement_live.name

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/${module.department_children_family_services_data_source.identifier}/synergy/Hackney_CaseManagement_Live"
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
  tags = module.tags.values
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
  tags = module.tags.values
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
  tags = module.tags.values
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
    path = "s3://${module.raw_zone_data_source.bucket_id}/${each.value.identifier}/google-sheets-new/"
  }

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
  tags = module.tags.values
}


# Academy crawlers for raw zone
resource "aws_glue_crawler" "benefits_housing_needs_academy_raw_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "benefits-housing-needs-academy-raw-zone"
  role          = module.department_benefits_and_housing_needs_data_source.glue_role_arn
  database_name = aws_glue_catalog_database.temp_benefits_housing_needs_academy.name # This is a temp database will change to raw zone database when ready

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/benefits-housing-needs/academy"
  }

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
  tags = module.tags.values
}

resource "aws_glue_crawler" "revenues_academy_raw_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "revenues-academy-raw-zone"
  role          = module.department_revenues_data_source.glue_role_arn
  database_name = aws_glue_catalog_database.temp_revenues_academy.name # This is a temp database will change to raw zone database when ready

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/revenues/academy"
  }

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
  tags = module.tags.values
}
