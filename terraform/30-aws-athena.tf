resource "aws_athena_database" "raw_zone_athena_database" {
  provider = aws.core

  name = replace("${local.identifier_prefix}-raw-zone-database", "-", "_")
  bucket = aws_s3_bucket.athena_storage_bucket.bucket
}