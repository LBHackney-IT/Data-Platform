# Google Drive Spreadsheet Imports for Child & Family Services
#
# 📋 CONFIGURATION: Edit the YAML File: 09-child-fam-service-spreadsheet-imports.yaml

locals {
  # Load configuration from YAML file
  yaml_config = yamldecode(file("${path.module}/09-child-fam-service-spreadsheet-imports.yaml"))

  # Convert YAML list to map for Terraform for_each
  spreadsheet_imports = {
    for sheet in local.yaml_config.spreadsheets :
    sheet.name => {
      google_drive_document_id = sheet.google_drive_document_id
      input_file_name          = sheet.input_file_name
      worksheet_name           = sheet.worksheet_name
      header_row_number        = sheet.header_row_number
    }
  }
}

locals {
  common_spreadsheet_config = {
    department                     = module.department_child_fam_service_data_source
    glue_scripts_bucket_id         = module.glue_scripts_data_source.bucket_id
    glue_catalog_database_name     = module.department_child_fam_service_data_source.raw_zone_catalog_database_name
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
    raw_zone_bucket_id             = module.raw_zone_data_source.bucket_id
    output_folder_name             = "g-drive"
    ingestion_schedule             = "cron(0 2 * * ? *)" # 2 AM UTC daily
    enable_bookmarking             = true
    tags                           = module.tags.values
  }
}

module "child_fam_spreadsheet_imports" {
  for_each = local.is_live_environment ? local.spreadsheet_imports : {}

  source = "../modules/import-spreadsheet-file-from-g-drive"

  is_production_environment      = local.is_production_environment
  is_live_environment            = local.is_live_environment
  department                     = local.common_spreadsheet_config.department
  glue_scripts_bucket_id         = local.common_spreadsheet_config.glue_scripts_bucket_id
  glue_catalog_database_name     = local.common_spreadsheet_config.glue_catalog_database_name
  glue_temp_storage_bucket_id    = local.common_spreadsheet_config.glue_temp_storage_bucket_id
  spark_ui_output_storage_id     = local.common_spreadsheet_config.spark_ui_output_storage_id
  secrets_manager_kms_key        = local.common_spreadsheet_config.secrets_manager_kms_key
  glue_role_arn                  = local.common_spreadsheet_config.glue_role_arn
  helper_module_key              = local.common_spreadsheet_config.helper_module_key
  pydeequ_zip_key                = local.common_spreadsheet_config.pydeequ_zip_key
  jars_key                       = local.common_spreadsheet_config.jars_key
  spreadsheet_import_script_key  = local.common_spreadsheet_config.spreadsheet_import_script_key
  identifier_prefix              = local.common_spreadsheet_config.identifier_prefix
  lambda_artefact_storage_bucket = local.common_spreadsheet_config.lambda_artefact_storage_bucket
  landing_zone_bucket_id         = local.common_spreadsheet_config.landing_zone_bucket_id
  landing_zone_kms_key_arn       = local.common_spreadsheet_config.landing_zone_kms_key_arn
  landing_zone_bucket_arn        = local.common_spreadsheet_config.landing_zone_bucket_arn
  raw_zone_bucket_id             = local.common_spreadsheet_config.raw_zone_bucket_id
  output_folder_name             = local.common_spreadsheet_config.output_folder_name
  enable_bookmarking             = local.common_spreadsheet_config.enable_bookmarking
  tags                           = local.common_spreadsheet_config.tags

  # Import-specific parameters (from each spreadsheet_imports entry)
  google_drive_document_id = each.value.google_drive_document_id
  glue_job_name            = replace(title(replace(each.key, "_", " ")), " ", "_") # Convert key to proper job name
  input_file_name          = each.value.input_file_name
  ingestion_schedule       = lookup(each.value, "ingestion_schedule", local.common_spreadsheet_config.ingestion_schedule)

  # Worksheet configuration
  worksheets = {
    sheet1 = {
      header_row_number = lookup(each.value, "header_row_number", 0)
      worksheet_name    = each.value.worksheet_name
    }
  }
}
