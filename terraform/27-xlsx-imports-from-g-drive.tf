module "repairs_fire_alarm_aov" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-xlsx-file-from-g-drive"
  department                     = module.department_housing_repairs
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_sheets_document_id      = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
  glue_job_name                  = "Electrical Mechanical Fire Safety Repairs"
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
    
module "env_enforcement_estate_cleaning" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-xlsx-file-from-g-drive"
  department                     = module.department_env_enforcement
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_sheets_document_id      = "1brqikq1CaMGqujqWTKa4S71NYoOpDP2p"
  glue_job_name                  = "Estate Cleaning"
  output_folder_name             = "estate-cleaning"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "c_r_cleaner_report__areas_1_-4_from_january_2022.xlsx"
  worksheets = {
    sheet1 : {
      header_row_number = 1
      worksheet_name    = "Estate cleaning Area 1"
    }
    sheet2 : {
      header_row_number = 1
      worksheet_name    = "Estate cleaning Area 2"
    }
    sheet3 : {
      header_row_number = 1
      worksheet_name    = "Estate cleaning Area 3"
    }
    sheet4 : {
      header_row_number = 1
      worksheet_name    = "Estate cleaning Area 4"
    }
  }
}

module "env_enforcement_fix_my_street_noise" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-xlsx-file-from-g-drive"
  department                     = module.department_env_enforcement
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_sheets_document_id      = "1kUizzzxaD6T1qX2hMNIrxuowdWUCxvbP"
  glue_job_name                  = Fix My Street Noise"
  output_folder_name             = "fix-my-street-noise"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "noise_fms_01012021_to_date.xlsx"
  worksheets = {
    sheet1 : {
      header_row_number = 1
      worksheet_name    = "Sheet1"
    }
  }
}

module "env_enforcement_cc_tv" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-xlsx-file-from-g-drive"
  department                     = module.department_env_enforcement
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  xlsx_import_script_key         = aws_s3_bucket_object.xlsx_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_sheets_document_id      = "13uiSwGDj-EPTVTUJtJgqbz2UabyRuFmw"
  glue_job_name                  = CCTV"
  output_folder_name             = "cc-tv"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "cctv.xlsx"
  worksheets = {
    sheet1 : {
      header_row_number = 1
      worksheet_name    = "Sheet1"
    }
  }
}
