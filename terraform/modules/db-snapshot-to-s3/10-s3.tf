module "rds_export_storage" {
  source = "../s3-bucket"

  tags              = var.tags
  project           = var.project
  environment       = var.environment
  identifier_prefix = var.identifier_prefix
  bucket_name       = "RDS Export Storage"
  bucket_identifier = "rds-export-storage${var.aws_account_suffix}"
  role_arns_to_share_access_with = [
    aws_iam_role.rds_snapshot_to_s3_lambda.arn
  ]
}
