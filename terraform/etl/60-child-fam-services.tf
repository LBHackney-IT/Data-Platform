# mosaic ETL resources

resource "aws_glue_crawler" "mosaic_raw_zone" {
  count         = local.is_live_environment ? 1 : 0
  name          = "${local.short_identifier_prefix}${module.department_children_family_services_data_source.identifier}-mosaic-raw-zone"
  role          = module.department_children_family_services_data_source.glue_role_arn
  database_name = aws_glue_catalog_database.mosaic_raw_zone.name

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
