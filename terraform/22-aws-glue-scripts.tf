resource "aws_s3_bucket_object" "google_sheets_import_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/google_sheets_import.py"
  acl    = "private"
  source = "../scripts/google_sheets_import.py"
  etag   = filemd5("../scripts/google_sheets_import.py")
}

resource "aws_s3_bucket_object" "address_matching" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/address_matching.py"
  acl    = "private"
  source = "../scripts/address_matching.py"
  etag   = filemd5("../scripts/address_matching.py")
}

resource "aws_s3_bucket_object" "levenshtein_address_matching" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/levenshtein_address_matching.py"
  acl    = "private"
  source = "../scripts/levenshtein_address_matching.py"
  etag   = filemd5("../scripts/levenshtein_address_matching.py")
}

resource "aws_s3_bucket_object" "copy_manually_uploaded_csv_data_to_raw" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/copy_manually_uploaded_csv_data_to_raw.py"
  acl    = "private"
  source = "../scripts/copy_manually_uploaded_csv_data_to_raw.py"
  etag   = filemd5("../scripts/copy_manually_uploaded_csv_data_to_raw.py")
}

resource "aws_s3_bucket_object" "address_cleaning" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/address_cleaning.py"
  acl    = "private"
  source = "../scripts/address_cleaning.py"
  etag   = filemd5("../scripts/address_cleaning.py")
}

resource "aws_s3_bucket_object" "helpers" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/helpers.py"
  acl    = "private"
  source = "../scripts/helpers.py"
  etag   = filemd5("../scripts/helpers.py")
}

resource "aws_s3_bucket_object" "jars" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "jars/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
  acl    = "private"
  source = "../external-lib/target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
  etag   = filemd5("../external-lib/target/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar")
}

resource "aws_s3_bucket_object" "deeque_jar" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "jars/deequ-1.0.3.jar"
  acl    = "private"
  source = "../external-lib/target/deequ-1.0.3.jar"
  etag   = filemd5("../external-lib/target/deequ-1.0.3.jar")
}

resource "aws_s3_bucket_object" "pydeequ" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "python-modules/pydeequ-1.0.1.zip"
  acl    = "private"
  source = "../external-lib/target/pydeequ-1.0.1.zip"
  etag   = filemd5("../external-lib/target/pydeequ-1.0.1.zip")
}

resource "aws_s3_bucket_object" "repairs_cleaning_helpers" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/repairs_cleaning_helpers.py"
  acl    = "private"
  source = "../scripts/repairs_cleaning_helpers.py"
  etag   = filemd5("../scripts/repairs_cleaning_helpers.py")
}

resource "aws_s3_bucket_object" "xlsx_import_script" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/xlsx_import.py"
  acl    = "private"
  source = "../scripts/xlsx_import.py"
  etag   = filemd5("../scripts/xlsx_import.py")
}

resource "aws_s3_bucket_object" "get_uprn_from_uhref" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/get_uprn_from_uhref.py"
  acl    = "private"
  source = "../scripts/get_uprn_from_uhref.py"
  etag   = filemd5("../scripts/get_uprn_from_uhref.py")
}

resource "aws_s3_bucket_object" "copy_liberator_landing_to_raw" {
  tags = module.tags.values

  bucket = module.glue_scripts.bucket_id
  key    = "scripts/copy_liberator_landing_to_raw.py"
  acl    = "private"
  source = "../scripts/copy_liberator_landing_to_raw.py"
  etag   = filemd5("../scripts/copy_liberator_landing_to_raw.py")
}

