data "archive_file" "liberator_data_upload_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/liberator-sftp-to-s3"
  output_path = "../lambdas/liberator-sftp-to-s3.zip"
}

resource "aws_s3_bucket_object" "liberator_data_upload_lambda" {
  tags = var.tags

  bucket = var.lambda_artefact_storage_bucket_name
  key    = "liberator-sftp-to-s3.zip"
  source = data.archive_file.liberator_data_upload_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.liberator_data_upload_lambda.output_md5
}