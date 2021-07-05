output "glue_job_name" {
  description = "Glue job name"
  value       = aws_glue_job.google_sheet_import.name
}
output "crawler_name" {
  description = "Glue job name"
  value       = aws_glue_crawler.google_sheet_import.name
}

output "workflow_name" {
  value = aws_glue_workflow.workflow.name
}
