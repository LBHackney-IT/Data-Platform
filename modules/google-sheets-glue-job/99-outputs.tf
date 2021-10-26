output "glue_job_name" {
  description = "Glue job name"
  value       = module.google_sheet_import.job_name
}

output "crawler_name" {
  description = "Crawler name"
  value       = module.google_sheet_import.crawler_name
}

output "workflow_name" {
  description = "Workflow name"
  value       = aws_glue_workflow.workflow.name
}
