module "manually_uploaded_parking_data_to_raw" {
  source = "../modules/aws-glue-job"

  count = local.is_live_environment ? 1 : 0

  department = module.department_parking
  job_name   = "${local.short_identifier_prefix}Parking Copy Manually Uploaded CSVs to Raw"
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--s3_bucket_target"    = module.raw_zone.bucket_id
    "--s3_bucket_source"    = module.landing_zone.bucket_id
    "--s3_prefix"           = "parking/manual/"
    "--extra-py-files"      = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
  }
  script_s3_object_key = aws_s3_bucket_object.copy_manually_uploaded_csv_data_to_raw.key
  trigger_enabled      = false
  crawler_details = {
    database_name      = module.department_parking.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/parking/manual/"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 4
      }
    })
  }
}
