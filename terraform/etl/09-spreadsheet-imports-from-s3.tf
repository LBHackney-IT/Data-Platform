module "parking_csv_import" {
  count                         = local.is_live_environment ? 0 : 1
  source                        = "../modules/s3-file-ingestion"
  config_file                   = "parking.yml"
  glue_scripts_bucket_id        = module.glue_scripts_data_source.bucket_id
  glue_temp_storage_bucket_id   = module.glue_temp_storage_data_source.bucket_url
  helper_module_key             = data.aws_s3_object.helpers.key
  identifier_prefix             = local.identifier_prefix
  is_live_environment           = local.is_live_environment
  is_production_environment     = local.is_production_environment
  jars_key                      = data.aws_s3_object.jars.key
  landing_zone_bucket_id        = module.landing_zone_data_source.bucket_id
  pydeequ_zip_key               = data.aws_s3_object.pydeequ.key
  raw_zone_bucket_id            = module.raw_zone_data_source.bucket_id
  spark_ui_output_storage_id    = module.spark_ui_output_storage_data_source.bucket_id
  spreadsheet_import_script_key = aws_s3_object.spreadsheet_import_script.key
  department                    = module.department_parking_data_source
}