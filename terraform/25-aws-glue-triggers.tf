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

resource "aws_glue_trigger" "landing_zone_liberator_crawled" {
  tags = module.tags.values

  name          = "${local.identifier_prefix} Landing Zone Liberator Crawled"
  type          = "CONDITIONAL"
  enabled       = true
  workflow_name = aws_glue_workflow.parking_liberator_data.name

  predicate {
    conditions {
      crawl_state  = "SUCCEEDED"
      crawler_name = aws_glue_crawler.landing_zone_liberator.name
    }
  }

  actions {
    job_name = aws_glue_job.copy_parking_liberator_landing_to_raw.name
  }

  actions {
    job_name = aws_glue_job.copy_env_enforcement_liberator_landing_to_raw.name
  }
}
