#Update the catalog databases in Pre-Production to catch the raw Academy data that was copied over from Production

#revenues raw zone database
resource "aws_glue_catalog_database" "revenues_raw_zone" {
    count = !local.is_production_environment ? 1 : 0
    name = "${local.short_identifier_prefix}revenues-raw-zone"
}

#revenues raw zone crawler
resource "aws_glue_crawler" "revenue_raw_zone" {
    count = !local.is_production_environment ? 1 : 0
    tags = module.tags.values
    
    database_name = aws_glue_catalog_database.revenues_raw_zone[0].name
    name = "${local.short_identifier_prefix}revenues-raw-zone"
    role = aws_iam_role.glue_role.arn

    s3_target {
        path = "s3://${module.raw_zone.bucket_id}/revenues/"
    }

    configuration = jsonencode({
        Version = 1.0
        Grouping = {
            TableLevelConfiguration = 3
        }

        TableGroupingPolicy = "CombineCompatibleSchemas"             

        Partitions = {  
            AddOrUpdateBehavior = "InheritFromTable"  
         }
    })
}

#benefits and housing needs raw zone database
resource "aws_glue_catalog_database" "bens_housing_needs_raw_zone" {
    count = !local.is_production_environment ? 1 : 0
    name = "${local.short_identifier_prefix}bens-housing-needs-raw-zone"
}

#benefits and housing needs raw zone crawler
resource "aws_glue_crawler" "bens_housing_needs_raw_zone" {
    count = !local.is_production_environment ? 1 : 0
    tags = module.tags.values

    database_name = aws_glue_catalog_database.bens_housing_needs_raw_zone[0].name
    name = "${local.short_identifier_prefix}bens-housing-needs-raw-zone"
    role = aws_iam_role.glue_role.arn

    s3_target {
        path = "s3://${module.raw_zone.bucket_id}/benefits-housing-needs/"
    }

     configuration = jsonencode({
        Version = 1.0
        Grouping = {
            TableLevelConfiguration = 3
        }

        TableGroupingPolicy = "CombineCompatibleSchemas"         

        Partitions = {  
            AddOrUpdateBehavior = "InheritFromTable"  
         }  
    })
}