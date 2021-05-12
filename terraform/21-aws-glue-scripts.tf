resource "aws_s3_bucket_object" "google_sheets_import_script" {
  tags = module.tags.values

  bucket = aws_s3_bucket.glue_scripts_bucket.id
  key    = "scripts/google-sheets-import.py"
  acl    = "private"
  source = "../scripts/google-sheets-import.py"
  etag   = filemd5("../scripts/google-sheets-import.py")
}
