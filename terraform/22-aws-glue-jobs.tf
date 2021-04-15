# Import test data
resource "aws_glue_job" "glue_job_google_sheet_import_test" {
  provider = aws.core
  tags = module.tags.values

  name = "Google Sheets Import Job - Test"
  role_arn = aws_iam_role.glue_role.arn
  command {
    python_version = "3"
    script_location = "s3://${aws_s3_bucket.glue_scripts_bucket.id}/${aws_s3_bucket_object.google_sheets_import_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--TempDir" = "s3://${aws_s3_bucket.glue_temp_storage_bucket.id}"
    "--additional-python-modules" = "gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1"
    "--s3_bucket_target" = "s3://${aws_s3_bucket.raw_zone_bucket.id}/test"
  }
}