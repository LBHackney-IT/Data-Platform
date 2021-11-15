resource "aws_athena_workgroup" "primary" {
  name  = "${local.short_identifier_prefix}primary"
  tags  = module.tags.values
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.athena_storage.bucket_id}/primary"

      encryption_configuration {
        encryption_option = "SSE_S3"
        kms_key_arn       = module.athena_storage.kms_key_arn
      }
    }
  }
}
