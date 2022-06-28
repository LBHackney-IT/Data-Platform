module "copy_icaseworks_data_landing_to_raw" {
  source = "../modules/aws-glue-job"

  count = local.is_live_environment ? 1 : 0

  job_name                   = "${local.short_identifier_prefix}iCaseworks (OneCase) Copy Landing to Raw"
  glue_role_arn              = data.aws_iam_role.glue_role.arn
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_s3_object_key       = data.aws_s3_bucket_object.copy_json_data_landing_to_raw.key
  glue_scripts_bucket_id     = module.glue_scripts_data_source.bucket_id
  glue_temp_bucket_id        = module.glue_temp_storage_data_source.bucket_id
  environment                = var.environment
  trigger_enabled            = false
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = "${module.raw_zone_data_source.bucket_id}/data-and-insight"
    "--s3_bucket_source"    = module.landing_zone_data_source.bucket_id
    "--s3_prefix"           = "icaseworks/"
    "--extra-py-files"      = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  crawler_details = {
    database_name      = module.department_data_and_insight_data_source.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone_data_source.bucket_id}/data-and-insight/icaseworks/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}