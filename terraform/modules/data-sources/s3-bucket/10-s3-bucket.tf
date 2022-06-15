data "aws_kms_key" "key" {
  key_id = lower("alias/${var.identifier_prefix}-s3-${var.bucket_identifier}")
}

data "aws_s3_bucket" "bucket" {
  bucket = lower("${var.identifier_prefix}-${var.bucket_identifier}")
}

data "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = data.aws_s3_bucket.bucket.id
}

data "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = data.aws_s3_bucket.bucket.id
}

data "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.bucket.id
}
