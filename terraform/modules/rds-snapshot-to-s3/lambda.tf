module "trigger_rds_snapshot_export" {
  source                         = "../aws-lambda"
  lambda_name                    = "rds-to-s3-copier"
  runtime                        = "python3.10"
  handler                        = "lambda_function.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  lambda_source_dir              = "../../lambdas/export_rds_snapshot_to_s3"
  lambda_output_path             = "../../lambdas/export-rds-snapshot-to-s3.zip"
  s3_key                         = "export-rds-snapshot-to-s3.zip"
  identifier_prefix              = var.identifier_prefix
  tags                           = var.tags
}

module "rds_snapshot_s3_to_s3_copier" {
  source                         = "../aws-lambda"
  lambda_name                    = "rds-export-s3-to-s3-copier"
  runtime                        = "python3.10"
  handler                        = "lambda_function.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  lambda_source_dir              = "../../lambdas/rds_export_s3_to_s3_copier"
  lambda_output_path             = "../../lambdas/rds-export-s3-to-s3-copier.zip"
  s3_key                         = "rds-export-s3-to-s3-copier.zip"
  identifier_prefix              = var.identifier_prefix
  tags                           = var.tags
}