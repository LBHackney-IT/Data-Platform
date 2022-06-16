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

