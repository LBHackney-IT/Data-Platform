resource "aws_s3_bucket_object" "google_sheets_import_script" {
  tags = module.tags.values

  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key    = "scripts/google-sheets-import.py"
  acl    = "private"
  source = "../scripts/google-sheets-import.py"
  etag   = filemd5("../scripts/google-sheets-import.py")
}

resource "aws_s3_bucket_object" "glue_job_template_script_to_raw" {
  tags = module.tags.values

  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key    = "scripts/glue-job-template-script-to-raw.py"
  acl    = "private"
  source = "../scripts/glue-job-template-script-to-raw.py"
  etag   = filemd5("../scripts/glue-job-template-script-to-raw.py")
}
