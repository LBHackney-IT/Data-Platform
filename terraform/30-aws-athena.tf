resource "aws_athena_workgroup" "parking" {
  tags = module.tags.values

  name  = "${local.identifier_prefix}-parking"
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.athena_storage.bucket_id}/parking/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = module.athena_storage.kms_key_arn
      }
    }
  }
}
