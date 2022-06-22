output "job_name" {
  value = module.spreadsheet_import.job_name
}

output "catalog_table" {
  value = replace("${var.department.identifier}_${var.data_set_name}", "-", "_")
}

output "worksheet_key" {
  value = local.worksheet_key
}

output "workflow_name" {
  value = data.aws_glue_workflow.workflow.id
}

output "crawler_name" {
  value = module.spreadsheet_import.crawler_name
}
