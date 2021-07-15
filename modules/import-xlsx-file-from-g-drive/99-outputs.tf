output "worksheet_resources" {
  value = tomap({
    for k in keys(module.import_data_from_xlsx_sheet_job) : module.import_data_from_xlsx_sheet_job[k].worksheet_key => {
      catalog_table = module.import_data_from_xlsx_sheet_job[k].catalog_table
      crawler_name  = module.import_data_from_xlsx_sheet_job[k].crawler_name
      job_arn       = module.import_data_from_xlsx_sheet_job[k].job_arn
      job_name      = module.import_data_from_xlsx_sheet_job[k].job_name
      workflow_name = module.import_data_from_xlsx_sheet_job[k].workflow_name
    }
  })
}
