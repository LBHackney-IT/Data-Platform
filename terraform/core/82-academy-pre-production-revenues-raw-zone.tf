#revenues raw zone crawler
resource "aws_glue_crawler" "revenues_raw_zone" {
    count = !local.is_production_environment ? 1 : 0
    tags = module.tags.values

    database_name = module.department_revenues.raw_zone_catalog_database_name
    name = "${local.short_identifier_prefix}revenues-raw-zone"
    role = aws_iam_role.glue_role.arn

    s3_target {
        path = "s3://${module.raw_zone.bucket_id}/revenues/"
    }

    configuration = jsonencode({
        Version = 1.0
        Grouping = {
            TableLevelConfiguration = 3
            TableGroupingPolicy = "CombineCompatibleSchemas"   
        }
        CrawlerOutput = {
            Partitions = {  
                AddOrUpdateBehavior = "InheritFromTable"  
            }
        }
    })
}
