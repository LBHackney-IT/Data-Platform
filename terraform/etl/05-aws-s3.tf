module "landing_zone_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "landing-zone"
}

module "raw_zone_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "raw-zone"
}

module "refined_zone_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "refined-zone"
}

module "trusted_zone_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "trusted-zone"
}

module "glue_scripts_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "glue-scripts"
}

module "glue_temp_storage_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "glue-temp-storage"
}

module "athena_storage_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "athena-storage"
}

module "lambda_artefact_storage_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "dp-lambda-artefact-storage"
}

module "spark_ui_output_storage_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "spark-ui-output-storage"
}

module "airflow" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "airflow"
}

module "noiseworks_data_storage_data_source" {
  source            = "../modules/data-sources/s3-bucket"
  identifier_prefix = local.identifier_prefix
  bucket_identifier = "noiseworks-data-storage"
}

data "aws_s3_object" "helpers" {
  bucket = module.glue_scripts_data_source.bucket_id
  key    = "python-modules/data_platform_glue_job_helpers-1.0-py3-none-any.whl"
}

data "aws_s3_object" "jars" {
  bucket = module.glue_scripts_data_source.bucket_id
  key    = "jars/java-lib-1.0-SNAPSHOT-jar-with-dependencies.jar"
}

data "aws_s3_object" "pydeequ" {
  bucket = module.glue_scripts_data_source.bucket_id
  key    = "python-modules/pydeequ-1.0.1.zip"
}

data "aws_s3_object" "copy_json_data_landing_to_raw" {
  bucket = module.glue_scripts_data_source.bucket_id
  key    = "scripts/copy_json_data_landing_to_raw.py"
}

resource "aws_s3_object" "google_sheets_import_script" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/google_sheets_import.py"
  acl         = "private"
  source      = "../../scripts/jobs/google_sheets_import.py"
  source_hash = filemd5("../../scripts/jobs/google_sheets_import.py")
}

resource "aws_s3_object" "address_matching" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/address_matching.py"
  acl         = "private"
  source      = "../../scripts/jobs/address_matching.py"
  source_hash = filemd5("../../scripts/jobs/address_matching.py")
}

resource "aws_s3_object" "levenshtein_address_matching" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/levenshtein_address_matching.py"
  acl         = "private"
  source      = "../../scripts/jobs/levenshtein_address_matching.py"
  source_hash = filemd5("../../scripts/jobs/levenshtein_address_matching.py")
}

resource "aws_s3_object" "copy_manually_uploaded_csv_data_to_raw" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/copy_manually_uploaded_csv_data_to_raw.py"
  acl         = "private"
  source      = "../../scripts/jobs/copy_manually_uploaded_csv_data_to_raw.py"
  source_hash = filemd5("../../scripts/jobs/copy_manually_uploaded_csv_data_to_raw.py")
}

resource "aws_s3_object" "address_cleaning" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/address_cleaning.py"
  acl         = "private"
  source      = "../../scripts/jobs/address_cleaning.py"
  source_hash = filemd5("../../scripts/jobs/address_cleaning.py")
}

resource "aws_s3_object" "convertbng" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "python-modules/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
  acl         = "private"
  source      = "../../scripts/lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
  source_hash = filemd5("../../scripts/lib/convertbng-0.6.36-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl")
}

resource "aws_s3_object" "deeque_jar" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "jars/deequ-1.0.3.jar"
  acl         = "private"
  source      = "../../external-lib/target/deequ-1.0.3.jar"
  source_hash = filemd5("../../external-lib/target/deequ-1.0.3.jar")
}

resource "aws_s3_object" "spreadsheet_import_script" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/spreadsheet_import.py"
  acl         = "private"
  source      = "../../scripts/jobs/spreadsheet_import.py"
  source_hash = filemd5("../../scripts/jobs/spreadsheet_import.py")
}

resource "aws_s3_object" "get_uprn_from_uhref" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/housing_repairs/get_uprn_from_uhref.py"
  acl         = "private"
  source      = "../../scripts/jobs/housing_repairs/get_uprn_from_uhref.py"
  source_hash = filemd5("../../scripts/jobs/housing_repairs/get_uprn_from_uhref.py")
}

resource "aws_s3_object" "copy_tables_landing_to_raw" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/copy_tables_landing_to_raw.py"
  acl         = "private"
  source      = "../../scripts/jobs/copy_tables_landing_to_raw.py"
  source_hash = filemd5("../../scripts/jobs/copy_tables_landing_to_raw.py")
}

resource "aws_s3_object" "copy_tables_landing_to_raw_backdated" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/copy_tables_landing_to_raw_backdated.py"
  acl         = "private"
  source      = "../../scripts/jobs/copy_tables_landing_to_raw_backdated.py"
  source_hash = filemd5("../../scripts/jobs/copy_tables_landing_to_raw_backdated.py")
}

resource "aws_s3_object" "housing_mtfh_case_notes_enriched_to_refined" {
  bucket      = module.glue_scripts_data_source.bucket_id # this is glue_scripts_data_source in etl folder
  key         = "scripts/housing_mtfh_case_notes_enriched.py"
  acl         = "private"
  source      = "../../scripts/jobs/housing/housing_mtfh_case_notes_enriched.py"
  source_hash = filemd5("../../scripts/jobs/housing/housing_mtfh_case_notes_enriched.py")
}
