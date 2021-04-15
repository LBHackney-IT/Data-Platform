//resource "aws_athena_database" "landing_zone_athena_database" {
//  name   = replace("${local.identifier_prefix}-landing-zone-database", "-", "_")
//  bucket = aws_s3_bucket.athena_storage_bucket.bucket
//
//  force_destroy = true
//
//  encryption_configuration {
//    encryption_option = "SSE_KMS"
//    kms_key = aws_kms_key.athena_storage_bucket_key.arn
//  }
//}

resource "aws_athena_workgroup" "workgroup" {
  tags = module.tags.values

  name = "${local.identifier_prefix}-workgroup"
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_storage_bucket.bucket}/output/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.athena_storage_bucket_key.arn
      }
    }
  }
}