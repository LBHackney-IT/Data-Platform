module "export-mtfh-pitr" {
  source                         = "../modules/aws-lambda"
  lambda_name                    = "dynamodb-pitr-export"
  lambda_source_dir              = "../lambdas/dynamodb-pitr-export"
  lambda_output_path             = "../lambdas/dynamodb_pitr_export.zip"
  handler                        = "main.lambda_handler"
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "dynamodb-pitr-export.zip"

  lambda_environment_variables = {
    SECRET_NAME = "${local.short_identifier_prefix}manual-mtfh-step-functions-mtfh-test"
  }
  tags = module.tags.values
}
