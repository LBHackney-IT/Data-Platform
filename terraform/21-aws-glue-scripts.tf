resource "aws_s3_bucket_object" "google_sheets_import_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/google-sheets-import.py"
  acl    = "private"
  source = "../scripts/google-sheets-import.py"
  etag   = filemd5("../scripts/google-sheets-import.py")
}

resource "aws_s3_bucket_object" "address_matching" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/address-matching.py"
  acl    = "private"
  source = "../scripts/address-matching.py"
  etag   = filemd5("../scripts/address-matching.py")
}

resource "aws_s3_bucket_object" "copy_manually_uploaded_csv_data_to_raw" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/copy-manually-uploaded-csv-data-to-raw.py"
  acl    = "private"
  source = "../scripts/copy-manually-uploaded-csv-data-to-raw.py"
  etag   = filemd5("../scripts/copy-manually-uploaded-csv-data-to-raw.py")
}
