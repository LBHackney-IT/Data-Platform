output "job_name" {
  value = aws_glue_job.xlsx_import.id
}

output "job_arn" {
  value = aws_glue_job.xlsx_import.arn
}

output "catalog_table" {
  value = local.worksheet_key
}

output "workflow_name" {
  value = aws_glue_workflow.workflow.id
}

output "crawler_name" {
  value =  aws_glue_crawler.xlsx_import.id
}
