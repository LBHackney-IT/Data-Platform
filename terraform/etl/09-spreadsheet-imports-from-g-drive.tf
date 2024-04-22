module "repairs_fire_alarm_aov" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_housing_repairs_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_housing_repairs_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
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
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_env_enforcement_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
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
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_env_enforcement_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_env_enforcement_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
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

module "data_and_insight_hb_combined" {
  count = local.is_live_environment ? 1 : 0

  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_data_and_insight_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
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

module "Cash_Collection_Date" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1HpKKtp_9b83Vqn5AwLOfFUSqW84Z10dA"
  glue_job_name                  = "Cash Collection Date"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Cash_Collection/Cash Collection mar 2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Cash_Collection"
    }
  }
}

module "Cedar_Backing_Data" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1yAH9bLcq19Ln1-Fz4CGx1YJFQUBkwCV6"
  glue_job_name                  = "Cedar Backing Data"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Cedar_Backing_Data/Cedar_Backing_mar_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Cedar_Backing_Data"
    }
  }
}

module "Cedar_Parking_Payments" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1_nqPjET8JFA1gsy4r2wSkp1xO62ovXUN"
  glue_job_name                  = "Cedar Parking Payments"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Cedar_Parking_Payments/Cedar_Parking_Payments_mar_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Cedar_Parking_Payments"
    }
  }
}

module "Citypay_Import" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1gy52yRuvlE4o93NWAShK9PdYlVChkgfz"
  glue_job_name                  = "Citypay Import"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "CityPay_Payments/Citypay_import_mar_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "CityPay_Payments"
    }
  }
}

module "Ringgo_Daily_Transactions" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1ga8q9JKNz1n7limX_l82KFwbvhcVscLa"
  glue_job_name                  = "Ringgo Daily Transactions"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Ringgo_Daily/Ringgo_Mar_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Ringgo_Daily"
    }
  }
}

module "Ringgo_session_forecast" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1pYUY2okmr6UWsbikPW-ZXIGZ_z44IHe8"
  glue_job_name                  = "Ringgo session forecast"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Ringgo_Session_Forecast/Ringgo_session_forecast_July_2022.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Ringgo_Session_Forecast"
    }
  }
}

module "Voucher_Import" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1T9MMh0wZv4ChvZt25jcf4j5CtnGht3nz"
  glue_job_name                  = "Voucher Import"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Visitor_Voucher_Forecast/Voucher Import_June_2022.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Visitor_Voucher_Forecast"
    }
  }
}
module "Permit_Diesel_Electric_Forecast" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1b6hcWaUFTV3_n8wewjHPkR3ewA_MJSK-"
  glue_job_name                  = "Permit Diesel Electric Forecast"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Permit_Diesel_Electric_Forecast/permit_diesel_electric_forecast_july.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "permit_diesel_electric_forecast"
    }
  }
}

module "housing_rent_position" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_housing_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_housing_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1ipYm_-LU28DbC_xIYxhvYCQQQKgWPoE9"
  glue_job_name                  = "housing rent position"
  output_folder_name             = "rent_statement"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "RentPosition.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "RentPosition"
    }
  }
}
module "parking_permits_consultation_hub_survey" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1NiwmqtbTwfLgwDWCvGlQp8nHt3TqiBBF"
  glue_job_name                  = "parking_permits_consultation_hub_survey"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Parking Permit Survey Consultation Hub/PermitsConsultationSurvey20221101-113601dddUTF8.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = false
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Parking Permit Survey Consultation Hub"
    }
  }
}
module "parking_eta_decision_records" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1M2BGAAGnU6m-dO4j9mG6ReyXn9oULpmI"
  glue_job_name                  = "parking_eta_decision_records"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "eta_decision_records/20221116-ETA_Decisions-GDSorQlikdataLoad-recordsUTF8.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = false
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "eta_decision_records"
    }
  }
}
module "pcn_permits_nlpg_llpg_matching_via_athena" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1OOIBcNE4Sk5c6u7zLDDAcwi72b6tHpn-"
  glue_job_name                  = "pcn_permits_nlpg_llpg_matching_via_athena"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "pcn_permits_nlpg_llpg_matching_via_athena/20221125to02-PCNPermVRMNLPGLLPGmatch-mergedddUTF8.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = false
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "parking_pcn_permit_nlpg_llpg_matching_via_athena"
    }
  }
}
module "unmatched_cedar_batches" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1huO76P35Jwv6uG9KfaHzq70110K6mH3J"
  glue_job_name                  = "unmatched_cedar_batches"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "unmatched_cedar_batches/unmatched_cedar_batch_sept_2023.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Unmatched_Cedar_Batch"
    }
  }
}
module "unmatched_citypay_batches" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1FCXFBYqqg7_GOT2ExB1I47fhQM0z7Lk8"
  glue_job_name                  = "unmatched_citypay_batches"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "unmatched_citypay_batches/citypay_unmatched_batches_sept_2023.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "unmatched_citypay_batch"
    }
  }
}
module "calendar" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1TV6GBIYZCWn3xt7YLfQZi9JRGCVS4I23"
  glue_job_name                  = "calendar"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "Calendar/Calendar Apr 2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "Calendar"
    }
  }
}
module "bailiff_return" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1GhzFODMREWl4mR8tYcLYBfHYJdZfSzKi"
  glue_job_name                  = "bailiff_return"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "bailiff_return/bailiff_return_03_04_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "bailiff_return"
    }
  }
}
module "bailiff_allocation" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1Ekn1co37j6qsg1q1F4cSe_4ot0Lcl91t"
  glue_job_name                  = "bailiff_allocation"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "bailiff_allocation/bailiff_allocation_03_01_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "bailiff_allocation"
    }
  }
}
module "bailiff_warrant_status" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1GmIaSIey1V2wzRHRzElGzysYiJPP-j0f"
  glue_job_name                  = "bailiff_warrant_status"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "bailiff_warrant_status/bailiff_warrant_status_03_01_2024.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = true
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "bailiff_warrant_status"
    }
  }
}
module "parking_cycle_hangar_denormalised_backfill" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1uIIS5WwGWi2hBLLOD8LhcafbkzvG0G1Z"
  glue_job_name                  = "parking_cycle_hangar_denormalised_backfill"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "cycle_hangar_denormalised_backfill/cycle hangar denormalised - backfill - 20220401 to 20231001 - UTF8.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = false
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "cycle hangar denormalised - backfill"
    }
  }
}
module "parking_max_user_records" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/import-spreadsheet-file-from-g-drive"
  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = module.department_parking_data_source
  glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
  glue_catalog_database_name     = module.department_parking_data_source.raw_zone_catalog_database_name
  glue_temp_storage_bucket_id    = module.glue_temp_storage_data_source.bucket_url
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  secrets_manager_kms_key        = data.aws_kms_key.secrets_manager_key
  glue_role_arn                  = data.aws_iam_role.glue_role.arn
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  jars_key                       = data.aws_s3_object.jars.key
  spreadsheet_import_script_key  = aws_s3_object.spreadsheet_import_script.key
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  landing_zone_bucket_id         = module.landing_zone_data_source.bucket_id
  landing_zone_kms_key_arn       = module.landing_zone_data_source.kms_key_arn
  landing_zone_bucket_arn        = module.landing_zone_data_source.bucket_arn
  google_drive_document_id       = "1STwKL-idm48rSQfMQ4pmqnJd9mYqyRqs"
  glue_job_name                  = "parking_max_user_records"
  output_folder_name             = "g-drive"
  raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
  input_file_name                = "max_user_source_records/max_user_journey_report_08_november_2022_30_june_2023_UTF8.csv"
  ingestion_schedule             = "cron(0 21 * * ? *)"
  enable_bookmarking             = false
  worksheets = {
    sheet1 : {
      header_row_number = 0
      worksheet_name    = "parking_max_user_journey_report"
    }
  }
}
