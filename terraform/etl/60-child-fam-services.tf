# mosaic ETL resources

resource "aws_glue_crawler" "mosaic_raw_zone" {
    count = local.is_live_environment ? 1 : 0
    name  = "${local.short_identifier_prefix}${module.department_child_and_family_services_data_source.identifier}mosaic-raw-zone"
    role  = module.department_child_and_family_services_data_source.glue_role_arn

    s3_target {
        path = "s3://${module.raw_zone_data_source.bucket_id}/${module.department_child_and_family_services_data_source.identifier}/mosaic/"
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
    count = local.is_live_environment ? 1 : 0
    name  = "${local.short_identifier_prefix}${module.department_child_and_family_services_data_source.identifier}allocations-refined-tables"
    role  = module.department_child_and_family_services_data_source.glue_role_arn

    s3_target {
        path = "s3://${module.refined_zone_data_source.bucket_id}/${module.department_child_and_family_services_data_source.identifier}/allocations/"
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
