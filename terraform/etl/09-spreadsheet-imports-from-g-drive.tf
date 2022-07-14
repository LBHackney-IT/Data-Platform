module "repairs_fire_alarm_aov" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_housing_repairs_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1VlM80P6J8N0P3ZeU8VobBP9kMbpr1Lzq"
  glue_job_name                  = "Electrical Mechanical Fire Safety Repairs"
  output_folder_name             = "repairs-electrical-mechanical-fire"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
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
  department                     = module.department_env_enforcement_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1swC26l9OdqCKMmox8h5nG2iEBtAUP-DA"
  glue_job_name                  = "Estate Cleaning"
  output_folder_name             = "estate-cleaning"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
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
  department                     = module.department_env_enforcement_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1kUizzzxaD6T1qX2hMNIrxuowdWUCxvbP"
  glue_job_name                  = "Fix My Street Noise"
  output_folder_name             = "fix-my-street-noise"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
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
  department                     = module.department_env_enforcement_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "13uiSwGDj-EPTVTUJtJgqbz2UabyRuFmw"
  glue_job_name                  = "CCTV"
  output_folder_name             = "cc-tv"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
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
  department                     = module.department_data_and_insight_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1tiMnVId0ERbCq47oPH0EOOyoDRCbhgr_"
  glue_job_name                  = "hb_combined snapshot for income max project"
  output_folder_name             = "hb_combined"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "HB_combined_timestamp.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220530"
    }
  }
}

module "eta_decision_records_gds_or_qlik_data_load_records_20220209" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1oWAo5-hmTnBH5lEUzjNkBf7-GxxfVXMG"
  glue_job_name                  = "ETA_Decisions - 20220209"
  output_folder_name             = "eta-decision-records"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220209 - ETA_Decisions - GDS or Qlik data Load - records.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220209"
    }
  }
}

module "eta_decision_records_gds_or_qlik_data_load_records_20220317" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1BgC7fEHRpOHO1NwPc8_HuIa9hJvDFqbH"
  glue_job_name                  = "ETA_Decisions - 20220317"
  output_folder_name             = "eta-decision-records"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220317 - ETA_Decisions - GDS or Qlik data Load - records.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220317"
    }
  }
}

module "eta_decision_records_gds_or_qlik_data_load_records_20220401" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1XqnMJR7-rjLl2MbVKChqRWu-DVWIACyr"
  glue_job_name                  = "ETA_Decisions - 20220401"
  output_folder_name             = "eta-decision-records"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220401 - ETA_Decisions - GDS or Qlik data Load - records UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220401"
    }
  }
}

module "eta_decision_records_gds_or_qlik_data_load_records_20220506" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1J_VdrUDgziXjYC6uy716jtFcEcZqjQP1"
  glue_job_name                  = "ETA_Decisions - 20220506"
  output_folder_name             = "eta-decision-records"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220506 - ETA_Decisions - GDS or Qlik data Load UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220506"
    }
  }
}

module "eta_decision_records_gds_or_qlik_data_load_records_20220420" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1FaBQhl-uoUMIIKppvcDsvctbqmiKzHen"
  glue_job_name                  = "ETA_Decisions - 20220420"
  output_folder_name             = "eta-decision-records"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220420 - ETA_Decisions - GDS or Qlik data Load - records.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220420"
    }
  }
}

module "eta_decision_records_gds_or_qlik_data_load_records_20220616" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1zNiIZNrv-vKZEuFBrzBzEYU93pclygYd"
  glue_job_name                  = "ETA_Decisions - 20220616"
  output_folder_name             = "eta-decision-records"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220616 - ETA_Decisions - GDS or Qlik data Load - records - UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220616"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220427" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1iDrqKGmIIpSkdnCoeAVmEJ0yFpgQXXvA"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG - 20220427"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220427 - PCNs VRM match to Permits VRM and NLPG by Registered and Current addresses Post Code - 13 months - final in glue via athena no comma fields removed dups UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220427"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220511" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1bVGcBiOKqn4fl95Ha3V7tRP0ZYZLwVR9"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG - 20220511"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220511 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220511"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220512" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "11SXSI88j4ae06a9jGaQ6Gdt0MGvYXbcB"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG - 20220512"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220512 - PCN Permits VRM NLPG LLPG matching - Last 3 months - UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220512"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220513" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1xNXCXZotqGiPkL7KnfvfiUzV5UaYwqlH"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG - 20220513"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220513 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220513"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220516" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "136qMDWhKA757B_NsfnQXEVfNUhT72eEn"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG - 20220516"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220516 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220516"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220629" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1jzSA1XA20tvkXw9s5QxhQPVNrcBtYlkk"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220629"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220629 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220629"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220628" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1orQnCHboCUp22g1588MXSLDikzeI8dn5"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220628"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220628 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220628"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220627" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "12SyIsc54-nsYTcbHT72AMYlOco_VX88K"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220627"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220627 - PCN Permits VRM NLPG LLPG matching - Last 3 months - UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220627"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220624" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1jyxLP2FYVqrCUOoTzAlzS0mp_8CVWWyi"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220624"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220624 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220624"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220623" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1dssQylsAqF5pcUfUyrjVY0qhxQOAmAOX"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220623"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220623 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220623"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220622" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1AY0HGOuUWdhZFeg1XD8RCCf9k0qhQpJQ"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220622"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220622 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220622"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220621" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1bECWtpHbCVhPio4PrPXsct-_Mn_fVnBk"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220621"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220621 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220621"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220617" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1ufP4bxO7UzriiULVj2bzK2AEPYEnyHlo"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220617"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220617 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220617"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220616" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1nWDwJi9x14s6foBNKj8S6ZszB5b2XGJ7"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220616"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220616 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220616"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220615" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "111w_v78KmEenZUdGGGmRIN0umJm7NuOT"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220615"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220615 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220615"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220614" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "13tb9CR5jMr_NotTUivC5BzzKmco2NwTu"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220614"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220614 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220614"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220613" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1XJu46qRaF3fT81vGEUuyVT0svcrp4awf"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220613"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220613 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220613"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220601" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1n4cmLgh5Isw7-n2Kiy8TVw7Npylu2K-N"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220601"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220601 - PCN Permits VRM NLPG LLPG matching - Last 3 months - UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220601"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220531" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1BeAJTPIPfEpQmUP7qwvkebUs5dS4xYv5"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220531"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220531 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220531"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220530" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1Qhs9UvqMmX1EUc8Fq7LYR9BVUr5YOwhK"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220530"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220530 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220530"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220527" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "12nLcB6gK84LMcberT0EywSduFxu44Qmw"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220527"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220527 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220527"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220526" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1xbUUP9Veagfj5qncFYaqEKL9YL0Z7hME"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220525"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220525 - PCN Permits VRM NLPG LLPG matching - Last 3 months - UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220525"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220524" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1WbiaLUn4dCwEMkvGFeyN4C4o201wL7C1"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220524"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220524 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220524"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220523" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1KYNvazjl0H2zYoRrFwaBKzevvN4hUNZQ"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220523"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220523 - PCN Permits VRM NLPG LLPG matching - Last 3 months with Company filter UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220523"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220519" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1CVkaYbvE475F0C1JTxBu_ZgFWtjKaMTG"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220519"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220519 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220519"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220518" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1HMtukW52hPrEmreezurwkHqd1d99-umJ"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220518"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220518 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220518"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220517" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "120bDNemRwC-f_w4czInbAlte0sttWh_t"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220517"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220517 - PCN Permits VRM NLPG LLPG matching - Last 3 months UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220517"
    }
  }
}

module "parking_pcn_permit_nlpg_llpg_matching_via_athena_20220714" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1mvzKB2HbQBOj3-tU9buPw5eSVGglQoPn"
  glue_job_name                  = "PCN Permits VRM NLPG LLPG matching - 20220714"
  output_folder_name             = "parking-pcn-permit-nlpg-llpg-matching-via-athena"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20220714 - PCN Permits VRM NLPG LLPG matching - Last 3 months - UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220714"
    }
  }
}

module "eta_decision" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1__tn7nTss2OsVURylMmqNq8zzE20ke2T"
  glue_job_name                  = "ETA_Decisions"
  output_folder_name             = "eta-decision"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "ETA_Decision.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "ETA_Decision"
    }
  }
}

module "permits_consultation_survey_20220506" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1iLScmA-tIvyoqOj3smbzkvzRhnfkDxOS"
  glue_job_name                  = "Permits Consultation Survey 20220506"
  output_folder_name             = "permits-consultation-survey"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permits Consultation Survey - export-2022-05-06-13-31-09 UTF-8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220506"
    }
  }
}

module "permits_consultation_survey_20210602" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1kkTU-FKe4b24lPQf0DGnOT3gPndHHY8S"
  glue_job_name                  = "Permits Consultation Survey 20210602"
  output_folder_name             = "permits-consultation-survey"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permits Consultation Survey - export-2021-06-02-11-58-45 UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20210602"
    }
  }
}

module "permits_consultation_survey_20210708" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1MAFFPGkyX5j1CrBQY41VDRW9OuvTgnxp"
  glue_job_name                  = "Permits Consultation Survey 20210708"
  output_folder_name             = "permits-consultation-survey"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permits Consultation Survey - export-2021-07-08-14-32-21.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20210708"
    }
  }
}

module "permits_consultation_survey_20211103" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1NZp50_o_dp10HuaZ0DzJBsCOiWDpab_w"
  glue_job_name                  = "Permits Consultation Survey 20211103"
  output_folder_name             = "permits-consultation-survey"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permits Consultation Survey - export-2021-11-03-12-23-16.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20211103"
    }
  }
}

module "permits_consultation_survey_20211104" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1s8KU2cqY7Kjn_WAIxbZjwr8UD6yNPBeA"
  glue_job_name                  = "Permits Consultation Survey 20211104"
  output_folder_name             = "permits-consultation-survey"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permits Consultation Survey - export-2021-11-04-11-12-22.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20211104"
    }
  }
}

module "permits_consultation_survey_20220601" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1VYcNHPH2DRk4qyHhS2ZPzc9-s4OECJbG"
  glue_job_name                  = "Permits Consultation Survey 20220601"
  output_folder_name             = "permits-consultation-survey"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permits Consultation Survey - export-2022-06-01-10-52-16 - UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20220601"
    }
  }
}

module "puzzel_total_overview_20210526" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1BBqhNGiZXVQBTXmLGKNXUqb11naAyiAS"
  glue_job_name                  = "Puzzel TotOview 20210526"
  output_folder_name             = "puzzel"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20210526 - Total Overview 10 05 2021 - 25 05 2021 - TotOview.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20210526"
    }
  }
}

module "puzzel_total_overview_20210526_UTF8" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1JFMumtYhEcOJhCyXUve4QfxAmNYmLkmp"
  glue_job_name                  = "Puzzel TotOview 20210526 UTF8"
  output_folder_name             = "puzzel"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "20210526 - Total Overview 10 05 2021 - 25 05 2021 - TotOview UTF8.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "20210526"
    }
  }
}

module "calendar" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "11hIukvOsZB0l2yNzMiPkl59vTXV5U0jI"
  glue_job_name                  = "Calendar"
  output_folder_name             = "calendar"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "calendar.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "calendar"
    }
  }
}

module "Cash_Collection_Date" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1ULDbN0CxL3AoLAznWMhphLiVL7mhRSH9"
  glue_job_name                  = "Cash Collection Date"
  output_folder_name             = "cash-collection"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Cash_Collection_Date.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Cash_Collection_Date"
    }
  }
}

module "Cedar_Backing_Data_May_2022" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "18jmhuuGc6okzhsGrrrChCOyYX3KCnxeN"
  glue_job_name                  = "Cedar Backing Data May 2022"
  output_folder_name             = "cedar-backing-data"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Cedar Backing May_2022.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Cedar_Backing_Data"
    }
  }
}

module "Cedar_Parking_Payments_May_2022" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1sfGLjFT5OiC71HwjyvmMiLg5xNdtGA6T"
  glue_job_name                  = "Cedar Parking Payments May 2022"
  output_folder_name             = "cedar-parking-payments"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Cedar_Parking_Payments_May_2022.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Cedar_Parking_Payments"
    }
  }
}

module "CEO_Beat_Streets_v2" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1Xb8sL8zvY-fLl4jLBIWzTllj7c_NM-Ob"
  glue_job_name                  = "CEO Beat Streets v2"
  output_folder_name             = "ceo-beat-streets"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Copy of Beat Streets v2.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Beat Streets v2"
    }
  }
}

module "CEO_Beat_Streets_within_zones_latest" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1hHBzrOFHnz5lUSemKFyIugIc-TtIW13c"
  glue_job_name                  = "Streets within Zones - latest"
  output_folder_name             = "ceo-beat-streets"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Streets within Zones - latest.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Streets within Zones - latest"
    }
  }
}

module "CEO_Beat_Streets_within_zones_update" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1QF3vpZQkID5FzWUfqSyPagwzy2tkZ-ob"
  glue_job_name                  = "Streets within Zones - Update"
  output_folder_name             = "ceo-beat-streets"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Streets within Zones - Update.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Streets within Zones - Update"
    }
  }
}

module "SStreet_CPZ_Visit_Targets_23112021" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1yzTmRgWcOHEYN5aWAWDz8olUGEB7saLh"
  glue_job_name                  = "Street CPZ Visit Targets - 23112021"
  output_folder_name             = "ceo-beat-visit-requirements"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Street_CPZ_Visit_Targets@23-11-2021_Latest_File.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Street_CPZ_Visit_Targets_23112021"
    }
  }
}

module "CEO_Visit_Timings_Full" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1BUI7Firtzt7Yskg2bIhLzj--S8KaF3WQ"
  glue_job_name                  = "CEO Visit Timings Full"
  output_folder_name             = "ceo-visit-req-timings"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "CEO Visit Timings_Full.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "CEO Visit Timings_Full"
    }
  }
}

module "Citypay_Import" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1lErUkzqr5O3V4Y13QSjHu6PlVeEPBREa"
  glue_job_name                  = "Citypay Import"
  output_folder_name             = "citypay-payments"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Citypay_Import.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Citypay_Import"
    }
  }
}

module "FixedSchoolStreetVRMs" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1Lsrb0Zi_snxDgeF078hP1GT_p6GLvYsl"
  glue_job_name                  = "Fixed School Street VRMs"
  output_folder_name             = "fixed-school-street-vrms"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "FixedSchoolStreetVRMs.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "FixedSchoolStreetVRMs"
    }
  }
}

module "BPLU_CLASS_PartyID_Address2" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1C229MLTUyXWloqph4KlutaBeU8YrwBfe"
  glue_job_name                  = "BPLU CLASS PartyID Address 2"
  output_folder_name             = "licensing-pp-addresses"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "BPLU_CLASS, PartyID and Address2.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "BPLU_CLASS_PartyID_Address2"
    }
  }
}

module "Licensing_BLPU_Class_PP_Addresses" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1_oDVH8lMTCDsODyCERDOMB7R2-Ln7Vg-"
  glue_job_name                  = "Licensing BLPU Class PP Addresses"
  output_folder_name             = "licensing-pp-addresses"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Licensing BLPU Class PP Addresses.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Licensing_BLPU_Class_PP_Addresses"
    }
  }
}

module "LTN_London_Fields" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1JAv1vyNtCB1q-oV59eoVdTGfbvI6vL7s"
  glue_job_name                  = "LTN London Fields"
  output_folder_name             = "ltn-london-fields"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "LTN_London_Fields.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "LTN_London_Fields"
    }
  }
}

module "OffenceCode" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1Mci0PtXcZ5FNzihbFTA7s2XckUQs5Se9"
  glue_job_name                  = "Offence Code"
  output_folder_name             = "offence-code"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "OffenceCode.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "OffenceCode"
    }
  }
}

module "PD_Location_Machines" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1Xb9S4UwG1YA7OkMHST1fxOANRGJ5FMBa"
  glue_job_name                  = "PD Location Machines"
  output_folder_name             = "pd-location-machines"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "PD_Location_Machines.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "PD_Location_Machines"
    }
  }
}

module "Ringg_Daily_Transactions_May_2022" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1VFkHrvQksmhmLRLgGgt6NBTHC8sREjwZ"
  glue_job_name                  = "Ringg Daily Transactions May 2022"
  output_folder_name             = "ringgo-daily"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Ringg_Daily_Transactions_May_2022.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Ringg_Daily_Transactions_May_2022"
    }
  }
}

module "Ringgo_Forecast_Mins" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "10HoVMwbrTUrIGiKZGcpUacHQh_s3xzsM"
  glue_job_name                  = "Ringgo Forecast Mins"
  output_folder_name             = "ringgo-mins-forecast"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Ringgo_Forecast_Mins.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Ringgo_Forecast_Mins"
    }
  }
}

module "Ringgo_session_forecast" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1uK92S_2IYfNUmGnV9WmnaJrjQREkjoT3"
  glue_job_name                  = "Ringgo session forecast"
  output_folder_name             = "ringgo-session-forecast"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Ringgo_session_forecast.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Ringgo_session_forecast"
    }
  }
}

module "School_Streets_19012022" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1DtnD_FLip4uOihzh539EtdjeJobSWWRA"
  glue_job_name                  = "School Streets 19012022"
  output_folder_name             = "school-street-camera-locations"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "School Streets_19012022.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "School_Streets_19012022"
    }
  }
}

module "school_street_extra" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1IOX44y5v9unE_acaCrcJlpu4kU0Ht803"
  glue_job_name                  = "school street extra"
  output_folder_name             = "school-street-uprn"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "school street extra.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "school_street_extra"
    }
  }
}

module "Voucher_Import" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_bucket_object.pydeequ.key
  jars_key                       = data.aws_s3_bucket_object.jars.key
  spreadsheet_import_script_key  = aws_s3_bucket_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1ZOdB9fL3z-x2k21dfSHyxpuZDr6tWbhl"
  glue_job_name                  = "Voucher Import"
  output_folder_name             = "visitor-voucher-forecast"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Voucher Import.csv"
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Voucher_Import"
    }
  }
}