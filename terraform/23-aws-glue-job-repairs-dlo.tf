resource "aws_s3_bucket_object" "housing_repairs_dlo_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_dlo_cleaning.py"
  acl    = "private"
  source = "../scripts/repairs_dlo_cleaning.py"
  etag   = filemd5("../scripts/repairs_dlo_cleaning.py")
}

resource "aws_glue_job" "housing_repairs_dlo_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Housing Repairs - Repairs DLO Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.housing_repairs_dlo_cleaning_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--source_catalog_database"          = module.department_housing_repairs.raw_zone_catalog_database_name
    "--source_catalog_table"             = "housing_repairs_repairs_dlo"
    "--cleaned_repairs_s3_bucket_target" = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/cleaned"
    "--TempDir"                          = module.glue_temp_storage.bucket_url
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_dlo_cleaned_crawler" {
  count = local.is_live_environment ? 1 : 0
  tags  = module.tags.values

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-dlo-cleaned"
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

resource "aws_glue_trigger" "housing_repairs_dlo_cleaning_job" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      crawler_name = module.repairs_dlo[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_dlo_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_dlo_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_dlo_cleaned_crawler[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_cleaning_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-address-cleaning-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_dlo_cleaned_crawler[0].name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_job.housing_repairs_dlo_address_cleaning[0].name
  }
}

resource "aws_glue_job" "housing_repairs_dlo_address_cleaning" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}DLO Repairs - Address Cleaning"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.address_cleaning.key}"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  glue_version = "2.0"

  default_arguments = {
    "--TempDir"        = module.glue_temp_storage.bucket_url
    "--extra-py-files" = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.repairs_cleaning_helpers.key}"
    "--source_catalog_database" : module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_catalog_table" : "housing_repairs_repairs_dlo_cleaned"
    "--cleaned_addresses_s3_bucket_target" : "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-cleaned-addresses"
    "--source_address_column_header" : "property_address"
    "--source_postcode_column_header" : "None"
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_cleaned_crawler_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-address-cleaned-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_dlo_address_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_dlo_with_cleaned_addresses_crawler[0].name
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_dlo_with_cleaned_addresses_crawler" {
  count = local.is_live_environment ? 1 : 0

  tags          = module.tags.values
  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-dlo-with-cleaned-addresses"
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

resource "aws_glue_trigger" "housing_repairs_dlo_cleaned_uhref_job_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-cleaned-uhref-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_dlo_with_cleaned_addresses_crawler[0].name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_job.get_uprn_from_uhref[0].name
  }
}

resource "aws_glue_job" "get_uprn_from_uhref" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Get UPRN from UHref DLO repairs"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.get_uprn_from_uhref.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--lookup_catalogue_table"      = "datainsight_data_and_insight"
    "--lookup_database"             = "dataplatform-stg-raw-zone-database"
    "--source_data_catalogue_table" = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--source_data_database"        = module.department_housing_repairs.refined_zone_catalog_database_name
    "--source_uhref_header"         = "property_reference_uh"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with_uprn_from_uhref/"
    "--TempDir"                     = module.glue_temp_storage.bucket_url
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_uprn_crawler_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-with-uprn-from-uhref-crawler"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      job_name = aws_glue_job.get_uprn_from_uhref[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_with_uprn_from_uhref_crawler[0].name
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_with_uprn_from_uhref_crawler" {
  tags  = module.tags.values
  count = local.is_live_environment ? 1 : 0

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-dlo-repairs-with-uprn-from-uhref"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing-repairs-with-uprn-from-uhref_"

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

resource "aws_glue_trigger" "housing_repairs_dlo_address_matching_job_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-address-matching-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.refined_zone_housing_repairs_with_uprn_from_uhref_crawler[0].name
      crawl_state  = "SUCCEEDED"
    }
  }
  actions {
    job_name = aws_glue_job.repairs_dlo_levenshtein_address_matching[0].name
  }
}

resource "aws_glue_job" "repairs_dlo_levenshtein_address_matching" {
  count = local.is_live_environment ? 1 : 0

  tags = module.tags.values

  name              = "Housing Repairs - Repairs DLO Levenshtein Address Matching"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = aws_iam_role.glue_role.arn
  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.levenshtein_address_matching.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--addresses_api_data_database" = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    "--addresses_api_data_table"    = "unrestricted_address_api_dbo_hackney_address"
    "--source_catalog_database"     = "housing-repairs-refined-zone"
    "--source_catalog_table"        = "housing_repairs_repairs_dlo_with_cleaned_addresses_with_cleaned_addresses"
    "--target_destination"          = "s3://${module.refined_zone.bucket_id}/housing-repairs/repairs-dlo/with-matched-addresses/"
    "--TempDir"                     = module.glue_temp_storage.bucket_url
    "--extra-py-files"              = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
}

resource "aws_glue_trigger" "housing_repairs_dlo_uprn_address_matched_crawler_trigger" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-dlo-with-matched-addresses"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name
  tags          = module.tags.values

  predicate {
    conditions {
      job_name = aws_glue_job.repairs_dlo_levenshtein_address_matching[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_dlo_with_matched_addresses_crawler[0].name
  }
}

resource "aws_glue_crawler" "refined_zone_housing_repairs_dlo_with_matched_addresses_crawler" {
  tags  = module.tags.values
  count = local.is_live_environment ? 1 : 0

  database_name = module.department_housing_repairs.refined_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}refined-zone-housing-repairs-dlo-with-matched-addresses"
  role          = aws_iam_role.glue_role.arn
  table_prefix  = "housing_repairs_dlo_with_matched_addresses_"

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
