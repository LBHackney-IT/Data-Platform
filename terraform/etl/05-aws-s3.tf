module "landing_zone" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "landing-zone"
}

module "raw_zone" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "raw-zone"
}

module "refined_zone" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "refined-zone"
}

module "trusted_zone" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "trusted-zone"
}

module "glue_scripts" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "glue-scripts"
}

module "glue_temp_storage" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "glue-temp-storage"
}

module "athena_storage" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "athena-storage"
}

module "lambda_artefact_storage" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "dp-lambda-artefact-storage"
}

module "spark_ui_output_storage" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "spark-ui-output-storage"
}

module "noiseworks_data_storage" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "noiseworks-data-storage"
}

data "aws_s3_bucket_object" "helpers" {
  bucket = module.glue_scripts.bucket_id
  key    = "python-modules/data_platform_glue_job_helpers-1.0-py3-none-any.whl"
}

data "aws_s3_bucket_object" "jars" {
  bucket = module.glue_scripts.bucket_id
  key    = "jars/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
}

data "aws_s3_bucket_object" "pydeequ" {
  bucket = module.glue_scripts.bucket_id
  key    = "python-modules/pydeequ-1.0.1.zip"
}

data "aws_s3_bucket_object" "ingest_database_tables_via_jdbc_connection" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/ingest_database_tables_via_jdbc_connection.py"
}

data "aws_s3_bucket_object" "copy_tables_landing_to_raw" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/copy_tables_landing_to_raw.py"
}

data "aws_s3_bucket_object" "dynamodb_tables_ingest" {
  bucket = module.glue_scripts.bucket_id
  key    = "scripts/ingest_tables_from_dynamo_db.py"
}

resource "aws_s3_bucket_object" "google_sheets_import_script" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/google_sheets_import.py"
  acl         = "private"
  source      = "../../scripts/jobs/google_sheets_import.py"
  source_hash = filemd5("../../scripts/jobs/google_sheets_import.py")
}

resource "aws_s3_bucket_object" "spreadsheet_import_script" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/spreadsheet_import.py"
  acl         = "private"
  source      = "../../scripts/jobs/spreadsheet_import.py"
  source_hash = filemd5("../../scripts/jobs/spreadsheet_import.py")
}

resource "aws_s3_bucket_object" "address_cleaning" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/address_cleaning.py"
  acl         = "private"
  source      = "../../scripts/jobs/address_cleaning.py"
  source_hash = filemd5("../../scripts/jobs/address_cleaning.py")
}

resource "aws_s3_bucket_object" "deeque_jar" {
  bucket      = module.glue_scripts.bucket_id
  key         = "jars/deequ-1.0.3.jar"
  acl         = "private"
  source      = "../../external-lib/target/deequ-1.0.3.jar"
  source_hash = filemd5("../../external-lib/target/deequ-1.0.3.jar")
}

resource "aws_s3_bucket_object" "address_matching" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/address_matching.py"
  acl         = "private"
  source      = "../../scripts/jobs/address_matching.py"
  source_hash = filemd5("../../scripts/jobs/address_matching.py")
}

resource "aws_s3_bucket_object" "levenshtein_address_matching" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/levenshtein_address_matching.py"
  acl         = "private"
  source      = "../../scripts/jobs/levenshtein_address_matching.py"
  source_hash = filemd5("../../scripts/jobs/levenshtein_address_matching.py")
}

resource "aws_s3_bucket_object" "copy_manually_uploaded_csv_data_to_raw" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/copy_manually_uploaded_csv_data_to_raw.py"
  acl         = "private"
  source      = "../../scripts/jobs/copy_manually_uploaded_csv_data_to_raw.py"
  source_hash = filemd5("../../scripts/jobs/copy_manually_uploaded_csv_data_to_raw.py")
}

resource "aws_s3_bucket_object" "get_uprn_from_uhref" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/housing_repairs/get_uprn_from_uhref.py"
  acl         = "private"
  source      = "../../scripts/jobs/housing_repairs/get_uprn_from_uhref.py"
  source_hash = filemd5("../../scripts/jobs/housing_repairs/get_uprn_from_uhref.py")
}

