module "g-drive-folder-to-s3" {
  count                          = !local.is_production_environment ? 1 : 0
  source                         = "../modules/aws-lambda-folder-ingestion"
  lambda_name                    = "g_drive_folder_to_s3"
  lambda_source_dir              = "../../lambdas/g_drive_folder_to_s3"
  lambda_output_path             = "../../lambdas/g_drive_folder_to_s3.zip"
  handler                        = "main.lambda_handler"
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "g_drive_folder_to_s3.zip"
  environment_variables = {
    SECRET_NAME = "${local.short_identifier_prefix}g_drive_folder_to_s3"
  }
  tags                 = module.tags.values
  install_requirements = true
}
