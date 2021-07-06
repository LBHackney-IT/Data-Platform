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

resource "aws_glue_trigger" "landing_zone_liberator_crawler_trigger" {
  tags = module.tags.values

  name          = "${local.identifier_prefix} Landing Zone Liberator Crawler"
  type          = "ON_DEMAND"
  enabled       = true
  workflow_name = aws_glue_workflow.liberator_data.name

  actions {
    crawler_name = aws_glue_crawler.landing_zone_liberator.name
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

resource "aws_glue_catalog_database" "raw_zone_parking_manual_uploads" {
  name = "${local.identifier_prefix}-raw-zone-parking-manual-uploads-database"
}

resource "aws_glue_crawler" "raw_zone_parking_manual_uploads_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_parking_manual_uploads.name
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

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_dlo_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-dlo-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_dlo_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_alpha_track_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-alpha-track-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_alpha_track_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-alpha-track/cleaned/"
    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}


resource "aws_glue_crawler" "refined_zone_housing_repairs_repairs_avonline_cleaned_crawler" {
  tags = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-repairs-avonline-cleaned"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_repairs_avonline_"

  s3_target {
    path       = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-avonline/cleaned/"
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
resource "aws_glue_trigger" "housing_repairs_repairs_dlo_cleaning_job" {
  name          = "${local.identifier_prefix}-housing-repairs-repairs-dlo-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo.workflow_name

  predicate {
    conditions {
      crawler_name = module.repairs_dlo.crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.repairs_dlo_cleaning.name
  }
}
resource "aws_glue_trigger" "housing_repairs_repairs_dlo_cleaning_crawler" {
  name          = "${local.identifier_prefix}-housing-repairs-repairs-dlo-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo.workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.repairs_dlo_cleaning.name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_repairs_dlo_cleaned_crawler.name
  }
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

