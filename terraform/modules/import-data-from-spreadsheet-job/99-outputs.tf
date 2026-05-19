output "job_name" {
  value = module.spreadsheet_import.job_name
}

output "job_arn" {
  value = module.spreadsheet_import.job_arn
}

output "catalog_table" {
  value = local.catalog_table
}

output "worksheet_key" {
  value = local.worksheet_key
}

output "workflow_name" {
  value = aws_glue_workflow.workflow.id
}

output "workflow_arn" {
  value = aws_glue_workflow.workflow.arn
}

output "crawler_name" {
  value = module.spreadsheet_import.crawler_name
}
