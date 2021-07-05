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

resource "aws_s3_bucket_object" "get_s3_subfolders" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/get_s3_subfolders.py"
  acl    = "private"
  source = "../scripts/get_s3_subfolders.py"
  etag   = filemd5("../scripts/get_s3_subfolders.py")
}

resource "aws_s3_bucket_object" "address_cleaning" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/address-cleaning.py"
  acl    = "private"
  source = "../scripts/address-cleaning.py"
  etag   = filemd5("../scripts/address-cleaning.py")
}

resource "aws_s3_bucket_object" "helpers" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/helpers.py"
  acl    = "private"
  source = "../scripts/helpers.py"
  etag   = filemd5("../scripts/helpers.py")
}

resource "aws_s3_bucket_object" "xlsx_import_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/xlsx-import.py"
  acl    = "private"
  source = "../scripts/xlsx-import.py"
  etag   = filemd5("../scripts/xlsx-import.py")
}


resource "aws_s3_bucket_object" "repairs_dlo_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs-dlo-cleaning.py"
  acl    = "private"
  source = "../scripts/repairs-dlo-cleaning.py"
  etag   = filemd5("../scripts/repairs-dlo-cleaning.py")
}


resource "aws_s3_bucket_object" "repairs_alphatrack_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs-alphatrack-cleaning.py"
  acl    = "private"
  source = "../scripts/repairs-alphatrack-cleaning.py"
  etag   = filemd5("../scripts/repairs-alphatrack-cleaning.py")
}


resource "aws_s3_bucket_object" "repairs_avonline_cleaning_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs-avonline-cleaning.py"
  acl    = "private"
  source = "../scripts/repairs-avonline-cleaning.py"
  etag   = filemd5("../scripts/repairs-avonline-cleaning.py")
}



resource "aws_s3_bucket_object" "empty_job" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/empty-job.py"
  acl    = "private"
  source = "../scripts/empty-job.py"
  etag   = filemd5("../scripts/empty-job.py")
}
