module "export-mtfh-pitr" {
  source                         = "../modules/aws-lambda"
  lambda_name                    = "mtfh-export-lambda"
  lambda_source_dir              = "../../lambdas/mtfh_export_lambda"
  lambda_output_path             = "../../lambdas/mtfh_export_lambda.zip"
  handler                        = "main.lambda_handler"
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "mtfh_export_lambda.zip"
  environment_variables = {
    SECRET_NAME = "${local.short_identifier_prefix}manual-mtfh-step-functions-mtfh-test"
  }
  tags = module.tags.values
}
