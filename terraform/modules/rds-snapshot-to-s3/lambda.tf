module "rds-to-s3-copier" {
  source                         = "../aws-lambda"
  lambda_name                    = "rds-to-s3-copier"
  runtime                        = "python3.8"
  handler                        = "lambda_function.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  lambda_source_dir              = "../../lambdas/s3-to-s3-export-copier-python"
  lambda_output_path             = "../../lambdas/rds-to-s3-copier.zip"
  s3_key                         = "rds-to-s3-copier.zip"
  identifier_prefix              = var.identifier_prefix
  tags                           = var.tags
}
