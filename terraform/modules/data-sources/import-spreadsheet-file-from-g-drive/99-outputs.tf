output "worksheet_resources" {
  value = tomap({
    for k in keys(module.import_data_from_spreadsheet_job_data_source) : module.import_data_from_spreadsheet_job_data_source[k].worksheet_key => {
      catalog_table = module.import_data_from_spreadsheet_job_data_source[k].catalog_table
      crawler_name  = module.import_data_from_spreadsheet_job_data_source[k].crawler_name
      job_arn       = module.import_data_from_spreadsheet_job_data_source[k].job_arn
      job_name      = module.import_data_from_spreadsheet_job_data_source[k].job_name
      workflow_name = module.import_data_from_spreadsheet_job_data_source[k].workflow_name
    }
  })
}
