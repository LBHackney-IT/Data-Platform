resource "aws_glue_catalog_database" "landing_zone_data_and_insight_address_matching" {
  count = local.is_live_environment ? 1 : 0

  name = "${local.identifier_prefix}-data-and-insight-address-matching-landing-zone"
}

resource "aws_glue_crawler" "landing_zone_data_and_insight_address_matching" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_data_and_insight_address_matching[count.index].name
  name          = "${local.identifier_prefix}-landing-zone-data-and-insight-address-matching"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/data-and-insight/address-matching-glue-job-output/"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

# ==== PARKING ======================================================================================================= #
resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}-landing-zone-database"
}

resource "aws_glue_catalog_database" "landing_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-landing-zone"
}

resource "aws_glue_crawler" "landing_zone_liberator" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_liberator.name
  name          = "${local.identifier_prefix}-landing-zone-liberator"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.landing_zone.bucket_id}/parking/liberator"
    exclusions = local.glue_crawler_excluded_blobs
  }
}

// ==== RAW ZONE ===========
resource "aws_glue_catalog_database" "raw_zone_unrestricted_address_api" {
  name = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"
}

resource "aws_glue_crawler" "raw_zone_unrestricted_address_api_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  name          = "${local.identifier_prefix}-raw-zone-unrestricted-address-api"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "unrestricted_address_api_"

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/unrestricted/addresses_api/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_crawler" "raw_zone_parking_manual_uploads_crawler" {
  tags = module.tags.values

  database_name = module.department_parking.raw_zone_catalog_database_name
  name          = "${local.identifier_prefix}-raw-zone-parking-manual-uploads-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.raw_zone.bucket_id}/parking/manual/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

// ==== REFINED ZONE ===========
resource "aws_glue_catalog_database" "refined_zone_liberator" {
  name = "${local.identifier_prefix}-liberator-refined-zone"
}

resource "aws_glue_crawler" "refined_zone_liberator_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.refined_zone_liberator.name
  name          = "${local.identifier_prefix}-refined-zone-liberator"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/parking/liberator/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_dlo_with_cleaned_addresses_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-dlo-with-cleaned-addresses"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_dlo_with_cleaned_addresses_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_dlo_with_matched_addresses_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-dlo-with-matched-addresses"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_dlo_with_matched_addresses_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-matched-addresses/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_with_uprn_from_uhref_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-with-uprn-from-uhref"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing-repairs-repairs-with-uprn-from-uhref_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}
