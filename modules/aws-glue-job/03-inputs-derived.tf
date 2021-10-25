locals {
  job_name_identifier = replace(lower(var.job_name), "/[^a-zA-Z0-9]+/", "-")
  crawler_details = defaults(var.crawler_details, {
    configuration = jsonencode({
      Version = 1.0
      CrawlerOutput = {
        Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
      }
    })
  })
}