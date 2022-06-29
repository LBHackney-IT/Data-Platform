output "glue_job_name" {
  description = "Glue job name"
  value       = module.google_sheet_import_data_source.job_name
}

output "crawler_name" {
  description = "Crawler name"
  value       = module.google_sheet_import_data_source.crawler_name
}

output "workflow_name" {
  description = "Workflow name"
  value       = data.aws_glue_workflow.workflow.name
}
