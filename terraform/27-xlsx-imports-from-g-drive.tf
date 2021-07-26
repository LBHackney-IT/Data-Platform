module "repairs_fire_alarm_aov" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-xlsx-file-from-g-drive"
  glue_role_arn                  = aws_iam_role.glue_role.arn
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  helpers_script_key             = aws_s3_bucket_object.helpers.key
  jars_key                       = aws_s3_bucket_object.jars.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  tags                           = module.tags.values
  google_sheets_document_id      = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
  glue_job_name                  = "Electrical Mechanical Fire Safety Repairs"
  department_folder_name         = "housing-repairs"
  output_folder_name             = "repairs-electrical-mechanical-fire"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "electrical_mechnical_fire_safety_temp_order_number_wc_12.10.20r1.xlsx"
  worksheets = {
    sheet1 : {
      header_row_number = 2
      worksheet_name    = "Door Entry"
    }
    sheet2 : {
      header_row_number = 2
      worksheet_name    = "Fire AlarmAOV"
    }
    sheet3 : {
      header_row_number = 2
      worksheet_name    = "Lightning Protection "
    }
    sheet4 : {
      header_row_number = 2
      worksheet_name    = "Electric Heating "
    }
    sheet5 : {
      header_row_number = 2
      worksheet_name    = "Electrical Supplies"
    }
    sheet6 : {
      header_row_number = 1
      worksheet_name    = "Lift Breakdown - ELA"
    }
    sheet7 : {
      header_row_number = 2
      worksheet_name    = "Communal Lighting"
    }
    sheet8 : {
      header_row_number = 2
      worksheet_name    = "Emergency Lighting Servicing "
    }
    sheet9 : {
      header_row_number = 2
      worksheet_name    = "Reactive Rewires"
    }
    sheet10 : {
      header_row_number = 2
      worksheet_name    = "Lift Servicing"
    }
    sheet11 : {
      header_row_number = 2
      worksheet_name    = "T.V Aerials"
    }
    sheet12 : {
      header_row_number = 2
      worksheet_name    = "DPA"
    }
  }
}
