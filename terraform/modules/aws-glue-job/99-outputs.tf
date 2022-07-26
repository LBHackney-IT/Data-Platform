output "crawler_name" {
  value = length(aws_glue_crawler.crawler) == 0 ? null : aws_glue_crawler.crawler[0].name
}

output "job_name" {
  value = aws_glue_job.job.name
}

output "job_arn" {
  value = aws_glue_job.job.arn
}

output "trigger_name" {
  value = aws_glue_trigger.job_trigger.name
}
