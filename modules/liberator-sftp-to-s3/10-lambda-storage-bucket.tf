resource "aws_s3_bucket" "parking_lambda_artefact_storage" {
  tags = var.tags

  bucket        = lower("${var.identifier_prefix}-parking-lambda-artefact-storage")
  acl           = "private"
  force_destroy = true
}

data "archive_file" "parking_liberator_data_upload_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/parking_liberator_sftp_to_s3"
  output_path = "../lambdas/parking_liberator_sftp_to_s3.zip"
}

resource "aws_s3_bucket_object" "parking_liberator_data_upload_lambda" {
  tags = var.tags

  bucket = aws_s3_bucket.parking_lambda_artefact_storage.id
  key    = "parking_liberator_data_upload_lambda.zip"
  source = data.archive_file.parking_liberator_data_upload_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.parking_liberator_data_upload_lambda.output_md5
}