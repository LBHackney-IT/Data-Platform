module "trigger_rds_snapshot_export" {
  source                         = "../aws-lambda"
  lambda_name                    = "export-rds-snapshot-to-s3"
  runtime                        = "python3.9"
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  lambda_source_dir              = "../../lambdas/export_rds_snapshot_to_s3"
  lambda_output_path             = "../../lambdas/export-rds-snapshot-to-s3.zip"
  s3_key                         = "export-rds-snapshot-to-s3.zip"
  identifier_prefix              = var.identifier_prefix
  tags                           = var.tags
  environment_variables = {
    "BUCKET_NAME"  = var.rds_export_bucket_id
    "IAM_ROLE_ARN" = aws_iam_role.rds_snapshot_to_s3_lambda_role.arn
    "KMS_KEY_ID"   = var.rds_export_storage_kms_key_id
  }
}

module "rds_snapshot_s3_to_s3_copier" {
  source                         = "../aws-lambda"
  lambda_name                    = "rds-export-s3-to-s3-copier"
  runtime                        = "python3.9"
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  lambda_source_dir              = "../../lambdas/rds_snapshot_export_s3_to_s3_copier"
  lambda_output_path             = "../../lambdas/rds_snapshot_export_s3_to_s3_copier.zip"
  s3_key                         = "rds-export-s3-to-s3-copier.zip"
  identifier_prefix              = var.identifier_prefix
  tags                           = var.tags
  environment_variables = {
    "SOURCE_BUCKET" = var.rds_export_bucket_id
    "TARGET_BUCKET" = var.target_bucket_id
    "SOURCE_PREFIX" = var.source_prefix
    "TARGET_PREFIX" = var.target_prefix
    "WORKFLOW_NAME" = var.workflow_name
  }
}
