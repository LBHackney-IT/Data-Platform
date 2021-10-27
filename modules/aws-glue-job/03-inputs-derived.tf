locals {
  job_name_identifier = replace(lower(var.job_name), "/[^a-zA-Z0-9]+/", "-")
  default_crawler_configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
  crawler_details = defaults(var.crawler_details, {
    configuration = local.default_crawler_configuration
  })
}