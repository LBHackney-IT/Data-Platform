resource "aws_s3_bucket" "liberator_lambda_artefact_storage" {
  tags = var.tags

  bucket        = lower("${var.identifier_prefix}-liberator-lambda-artefact-storage")
  acl           = "private"
  force_destroy = true
}

data "archive_file" "liberator_data_upload_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/liberator_sftp_to_s3"
  output_path = "../lambdas/liberator_sftp_to_s3.zip"
}

resource "aws_s3_bucket_object" "liberator_data_upload_lambda" {
  tags = var.tags

  bucket = aws_s3_bucket.liberator_lambda_artefact_storage.id
  key    = "liberator_sftp_to_s3.zip"
  source = data.archive_file.liberator_data_upload_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.liberator_data_upload_lambda.output_md5
}