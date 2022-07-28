module "tuomo_test_db_to_landing_zone" {
  source = "../modules/aws-glue-job"

  is_live_environment = false
  is_production_environment = false

  job_name    = "${local.short_identifier_prefix}tuomo test db person table from landing to raw"
  script_name = "tuomo_test_db_from_landing_to_raw_zone"

  helper_module_key = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key   = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  glue_version = "3.0"

  #schedule    = "cron(0 15 ? * TUE _)"

  #THIS IS REQUIRED BECAUSE DEPARTMENT IS NOT SET
  glue_role_arn = data.aws_iam_role.glue_role.arn
  
  glue_temp_bucket_id = "dataplatform-${local.short_identifier_prefix}glue-temp-storage"
  glue_scripts_bucket_id =  module.glue_scripts_data_source.bucket_id

  crawler_details = {
    database_name      = "dataplatform-${local.short_identifier_prefix}raw-zone-database"
    s3_target_location = "s3://dataplatform-${local.short_identifier_prefix}raw-zone/tuomo-test-db/"
  }
}