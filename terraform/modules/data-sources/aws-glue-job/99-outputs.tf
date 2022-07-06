output "crawler_name" {
  value = length(data.aws_glue_crawler.crawler) == 0 ? null : data.aws_glue_crawler.crawler[0].name
}

output "job_name" {
  value = data.aws_glue_job.job.name
}
