module "repairs_fire_alarm_aov" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_housing_repairs
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_drive_document_id       = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
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

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_env_enforcement
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_drive_document_id       = "1swC26l9OdqCKMmox8h5nG2iEBtAUP-DA"
  glue_job_name                  = "Estate Cleaning"
  output_folder_name             = "estate-cleaning"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "c_r_cleaner_report_areas_1-4_from_january_2022.xlsx"
  worksheets = {
    sheet1 : {
      header_row_number = 1
      worksheet_name    = "Area 1"
    }
    sheet2 : {
      header_row_number = 1
      worksheet_name    = "Area 2"
    }
    sheet3 : {
      header_row_number = 1
      worksheet_name    = "Area 3"
    }
    sheet4 : {
      header_row_number = 1
      worksheet_name    = "Area 4"
    }
  }
}

module "env_enforcement_fix_my_street_noise" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_env_enforcement
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_drive_document_id       = "1kUizzzxaD6T1qX2hMNIrxuowdWUCxvbP"
  glue_job_name                  = "Fix My Street Noise"
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

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_env_enforcement
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_drive_document_id       = "13uiSwGDj-EPTVTUJtJgqbz2UabyRuFmw"
  glue_job_name                  = "CCTV"
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

module "data_and_insight_hb_combined" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_data_and_insight
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_catalog_database_name     = module.department_data_and_insight.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
  glue_role_arn                  = aws_iam_role.glue_role.arn
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  jars_key                       = aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
  landing_zone_bucket_id         = module.landing_zone.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
  google_sheets_document_id      = "1tiMnVId0ERbCq47oPH0EOOyoDRCbhgr_"
  glue_job_name                  = "hb_combined snapshot for income max project"
  output_folder_name             = "hb_combined"
  raw_zone_bucket_id             = module.raw_zone.bucket_id
  input_file_name                = "HB_combined_timestamp.csv"
  worksheets = {
      sheet1 : {
        header_row_number = 0
        worksheet_name    = "20220530"
      }
  }
}

//module "parking_permits_consultation_survey" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1iLScmA-tIvyoqOj3smbzkvzRhnfkDxOS"
//  glue_job_name                  = "${title(module.department_parking.name)} Permits Consultation Survey"
//  output_folder_name             = "permits-consultation-survey"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "Permits Consultation Survey - export-2022-05-06-13-31-09 UTF-8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "2022-05-06-13-31-09"
//    }
//  }
//}
//
////g-drive-Bens-Housing-Needs-PCN-Permits-VRM-NLPG-LLPG-matching
//
//module "puzzel_total_overview_10_05_2021_to_25_05_2021_UTF8" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1xZmbsPENv01chzZcP661pv1d2Kmg7y6r"
//  glue_job_name                  = "${title(module.department_parking.name)} Puzzel 20210526 - Total Overview"
//  output_folder_name             = "puzzel"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20210526 - Total Overview 10 05 2021 - 25 05 2021 - TotOview UTF8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20210526"
//    }
//  }
//}
//
//module "eta_decision_records_gds_or_qlik_data_load_records_20220209" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1oWAo5-hmTnBH5lEUzjNkBf7-GxxfVXMG"
//  glue_job_name                  = "${title(module.department_parking.name)} 20220209 - ETA_Decisions"
//  output_folder_name             = "eta_decision_records"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220209 - ETA_Decisions - GDS or Qlik data Load - records.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220209"
//    }
//  }
//}
//
//module "eta_decision_records_gds_or_qlik_data_load_records_20220317" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1BgC7fEHRpOHO1NwPc8_HuIa9hJvDFqbH"
//  glue_job_name                  = "${title(module.department_parking.name)} 20220317 - ETA_Decisions"
//  output_folder_name             = "eta_decision_records"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220317 - ETA_Decisions - GDS or Qlik data Load - records.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220317"
//    }
//  }
//}
//
//module "eta_decision_records_gds_or_qlik_data_load_records_20220401" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1XqnMJR7-rjLl2MbVKChqRWu-DVWIACyr"
//  glue_job_name                  = "${title(module.department_parking.name)} 20220401 - ETA_Decisions"
//  output_folder_name             = "eta_decision_records"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220401 - ETA_Decisions - GDS or Qlik data Load - records UTF8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220401"
//    }
//  }
//}
//
//module "eta_decision_records_gds_or_qlik_data_load_records_20220506" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1J_VdrUDgziXjYC6uy716jtFcEcZqjQP1"
//  glue_job_name                  = "${title(module.department_parking.name)} 20220506 - ETA_Decisions"
//  output_folder_name             = "eta_decision_records"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220506 - ETA_Decisions - GDS or Qlik data Load UTF-8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220506"
//    }
//  }
//}
//
//module "eta_decision_records_gds_or_qlik_data_load_records_20220420" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1FaBQhl-uoUMIIKppvcDsvctbqmiKzHen"
//  glue_job_name                  = "${title(module.department_parking.name)} 20220420 - ETA_Decisions"
//  output_folder_name             = "eta_decision_records"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220420 - ETA_Decisions - GDS or Qlik data Load - records.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220420"
//    }
//  }
//}
//
//module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220427" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1thn-BsMfvyUP0dzcEHM2eWSen9dASC-O"
//  glue_job_name                  = "${title(module.department_parking.name)} PCN Permits VRM NLPG LLPG - 20220427"
//  output_folder_name             = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220427 - PCNs VRM match to Permits VRM and NLPG by Registered and Current addresses Post Code - 13 months - final in glue via athena no comma fields removed dups UTF8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220427"
//    }
//  }
//}
//
//module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220511" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1AEgRZdxPnALuXn4nqcqQtEBkvJPWXUh5"
//  glue_job_name                  = "${title(module.department_parking.name)} PCN Permits VRM NLPG LLPG - 20220511"
//  output_folder_name             = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220511 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220511"
//    }
//  }
//}
//
//module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220512" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1sKnfS2xruU1ZKvnd1Cwcys2PAyC4zHOD"
//  glue_job_name                  = "${title(module.department_parking.name)} PCN Permits VRM NLPG LLPG - 20220512"
//  output_folder_name             = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220512 - PCN Permits VRM NLPG LLPG matching - Last 3 months - UTF-8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220512"
//    }
//  }
//}
//
//module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220513" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1XWGudeZ3D5rbYXZL29sP_Q-n475yNP9e"
//  glue_job_name                  = "${title(module.department_parking.name)} PCN Permits VRM NLPG LLPG - 20220513"
//  output_folder_name             = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220513 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220513"
//    }
//  }
//}
//
//module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220516" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "16PbpKwBUMFxUWyB3mEMWRWZzxzZtDhoU"
//  glue_job_name                  = "${title(module.department_parking.name)} PCN Permits VRM NLPG LLPG - 20220516"
//  output_folder_name             = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220516 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220516"
//    }
//  }
//}
//module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220524" {
//  count                          = local.is_live_environment ? 1 : 0
//  source                         = "../modules/import-spreadsheet-file-from-g-drive"
//  department                     = module.department_parking
//  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
//  glue_catalog_database_name     = module.department_parking.raw_zone_catalog_database_name
//  glue_temp_storage_bucket_id    = module.glue_temp_storage.bucket_url
//  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
//  secrets_manager_kms_key        = aws_kms_key.secrets_manager_key
//  glue_role_arn                  = aws_iam_role.glue_role.arn
//  helper_module_key              = aws_s3_bucket_object.helpers.key
//  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
//  jars_key                       = aws_s3_bucket_object.jars.key
//  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
//  identifier_prefix              = local.short_identifier_prefix
//  lambda_artefact_storage_bucket = module.lambda_artefact_storage.bucket_id
//  landing_zone_bucket_id         = module.landing_zone.bucket_id
//  landing_zone_kms_key_arn       = module.landing_zone.kms_key_arn
//  landing_zone_bucket_arn        = module.landing_zone.bucket_arn
//  google_drive_document_id       = "1Nsly2YWLufSWpq6fRd-VWr2Tdkma7bQV"
//  glue_job_name                  = "${title(module.department_parking.name)} - PCN Permits VRM NLPG LLPG matching"
//  output_folder_name             = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
//  raw_zone_bucket_id             = module.raw_zone.bucket_id
//  input_file_name                = "20220524 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8 DP.csv"
//  worksheets = {
//    sheet1 : {
//      header_row_number = 0
//      worksheet_name    = "20220524"
//    }
//  }
//}
