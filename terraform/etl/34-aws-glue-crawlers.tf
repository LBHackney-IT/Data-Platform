// ==== RAW ZONE ===========
resource "aws_glue_catalog_database" "raw_zone_unrestricted_address_api" {
  name = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_glue_crawler" "raw_zone_unrestricted_address_api_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  name          = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"
  role          = data.aws_iam_role.glue_role.arn
  table_prefix  = "unrestricted_address_api_"

  s3_target {
    path       = "s3://${module.raw_zone_data_source.bucket_id}/unrestricted/addresses_api/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

# This is for a one-off manual crawler to transfer iCaseworks data to the catalogue in raw zone.
resource "aws_glue_crawler" "icaseworks_manual" {
  count         = local.is_live_environment ? 1 : 0
  tags          = module.tags.values
  name          = "${local.short_identifier_prefix}${module.department_data_and_insight_data_source.identifier}-icaseworks_manual"
  role          = data.aws_iam_role.glue_role.arn
  database_name = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/${module.department_data_and_insight_data_source.identifier}/icaseworks/"
  }
  table_prefix = "icaseworks_"

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

resource "aws_glue_trigger" "addresses_api_crawler_trigger" {
  tags = module.tags.values

  name     = "${local.short_identifier_prefix}Addresses API crawler Trigger"
  type     = "SCHEDULED"
  schedule = "cron(0 6 * * ? *)"
  enabled  = local.is_live_environment

  actions {
    crawler_name = aws_glue_crawler.raw_zone_unrestricted_address_api_crawler.name
  }
}

resource "aws_glue_crawler" "refined_zone_sandbox_crawler" {
  tags = module.tags.values

  database_name = module.department_sandbox_data_source.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}sandbox-refined-zone"
  role          = data.aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 3
    }
  })
}

// ==== ARCUS ARCHIVE ===========

resource "aws_glue_crawler" "arcus_archive" {
  count         = local.is_live_environment ? 1 : 0
  tags          = module.tags.values
  name          = "${local.short_identifier_prefix}arcus_archive"
  role          = data.aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.arcus_archive.name
  s3_target {
    path = "s3://${local.identifier_prefix}-arcus-data-storage/Hackney-Data-Extract/"
  }
}

// ==== TASCOMI DEBUG CRAWLERS ===========
// These crawlers are retained for manual debugging only and are intentionally
// detached from the removed Tascomi delete workflow jobs and triggers.
// They only exist in staging environments.

resource "aws_glue_crawler" "tascomi_api_response_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-api-response-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn
  table_prefix  = "api_response_"

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/planning/tascomi/api-responses/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_crawler" "tascomi_increment_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.refined_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-increment-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn
  table_prefix  = "increment_"

  s3_target {
    path       = "s3://${module.refined_zone_data_source.bucket_id}/planning/tascomi/increment/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_crawler" "tascomi_snapshot_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.refined_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-snapshot-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn

  s3_target {
    path       = "s3://${module.refined_zone_data_source.bucket_id}/planning/tascomi/snapshot/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_crawler" "tascomi_trusted_applications_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.trusted_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-trusted-applications-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn

  s3_target {
    path       = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/applications"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_crawler" "tascomi_trusted_officers_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.trusted_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-trusted-officers-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn

  s3_target {
    path       = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/officers"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_crawler" "tascomi_trusted_locations_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.trusted_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-trusted-locations-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn

  s3_target {
    path       = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/locations"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

resource "aws_glue_crawler" "tascomi_trusted_subsidiary_tables_manual_debug" {
  count = local.is_live_environment && !local.is_production_environment ? 1 : 0
  tags  = module.tags.values

  database_name = aws_glue_catalog_database.trusted_zone_tascomi.name
  name          = "${local.short_identifier_prefix}tascomi-trusted-subsidiary-tables-manual-debug"
  role          = module.department_planning_data_source.glue_role_arn

  s3_target {
    path       = "s3://${module.trusted_zone_data_source.bucket_id}/planning/tascomi/"
    exclusions = local.glue_crawler_excluded_blobs
  }
}
