#This terraform file is used for creating glue jobs during training.


#module "job_template" {
#  source                    = "../modules/aws-glue-job"
#  is_live_environment       = local.is_live_environment
#  is_production_environment = local.is_production_environment
#
#  department                 = module.department_sandbox_data_source
#  job_name                   = "${local.short_identifier_prefix}job_template"
#  script_name                = "job_script_template"
#  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
#  helper_module_key          = data.aws_s3_bucket_object.helpers.key
#  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
#  job_parameters = {
#    "--s3_bucket_target"        = "s3://${module.refined_zone_data_source.bucket_id}/sandbox/some-target-location-in-the-refined-zone"
#    "--source_catalog_database" = module.department_sandbox_data_source.raw_zone_catalog_database_name
#    "--source_catalog_table"    = "some_table_name"
#  }
#}

