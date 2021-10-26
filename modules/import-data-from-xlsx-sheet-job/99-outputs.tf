output "job_name" {
  value = module.xlsx_import.job_name
}

output "job_arn" {
  value = module.xlsx_import.job_arn
}

output "catalog_table" {
  value = replace("${var.department.identifier}_${var.data_set_name}", "-", "_")
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
  value = module.xlsx_import.crawler_name
}
