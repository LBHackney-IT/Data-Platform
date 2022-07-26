# module "tuomo_test_db_to_landing_zone" {
#   source = "../modules/aws-glue-job"

#     #will it work wihout department?!
#   #department  = module.department_housing_repairs
#   job_name    = "${local.short_identifier_prefix}tuomo test db person table from landing to raw"
#   script_name = "tuomo_test_db_from_landing_to_raw_zone"

#   helper_module_key = aws_s3_bucket_object.helpers.key
#   pydeequ_zip_key = aws_s3_bucket_object.pydeequ.key
#   spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id

#   schedule    = "cron(0 15 ? * TUE _)"

# ##THIS IS REQUIRED BECAUSE DEPARTMENT IS NOT SET
#   glue_role_arn = aws_iam_role.glue_role.arn

# #   job_parameters = {
# #     "--s3_bucket_source" = "${module.landing_zone.bucket_id}/manual/housing-repairs/repairs-axis/"
# #     "--s3_bucket_target" = "${module.raw_zone.bucket_id}/housing-repairs/repairs-axis/"
# #   }
# #   crawler_details = {
# #     database_name      = module.department_housing_repairs.raw_zone_catalog_database_name
# #     s3_target_location = "s3://${module.raw_zone.bucket_id}/housing-repairs/repairs-axis/"
# #     table_prefix       = "housing_repairs_"
# #   }
# }