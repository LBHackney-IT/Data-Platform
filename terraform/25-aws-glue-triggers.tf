resource "aws_glue_trigger" "landing_zone_liberator_crawler_trigger" {
  tags = module.tags.values

  name          = "${local.identifier_prefix} Landing Zone Liberator Crawler"
  type          = "ON_DEMAND"
  enabled       = true
  workflow_name = aws_glue_workflow.parking_liberator_data.name

  actions {
    crawler_name = aws_glue_crawler.landing_zone_liberator.name
  }
}

resource "aws_glue_trigger" "housing_repairs_repairs_dlo_cleaning_job" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-dlo-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name

  predicate {
    conditions {
      crawler_name = module.repairs_dlo[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.repairs_dlo_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_repairs_dlo_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-dlo-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_dlo[0].workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.repairs_dlo_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_repairs_dlo_cleaned_crawler.name
  }
}

resource "aws_glue_trigger" "housing_repairs_repairs_avonline_cleaning_job" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-avonline-cleaning-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_avonline[0].workflow_name

  predicate {
    conditions {
      crawler_name = module.repairs_avonline[0].crawler_name
      crawl_state  = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.housing_repairs_avonline_cleaning[0].name
  }
}

resource "aws_glue_trigger" "housing_repairs_repairs_avonline_cleaning_crawler" {
  count = local.is_live_environment ? 1 : 0

  name          = "${local.identifier_prefix}-housing-repairs-repairs-avonline-cleaning-crawler-trigger"
  type          = "CONDITIONAL"
  workflow_name = module.repairs_avonline[0].workflow_name

  predicate {
    conditions {
      job_name = aws_glue_job.housing_repairs_avonline_cleaning[0].name
      state    = "SUCCEEDED"
    }
  }
  actions {
    crawler_name = aws_glue_crawler.refined_zone_housing_repairs_repairs_avonline_cleaned_crawler.name
  }
}