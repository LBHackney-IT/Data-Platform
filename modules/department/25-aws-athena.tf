resource "aws_athena_workgroup" "department_workgroup" {
  tags = var.tags

  name  = "${var.short_identifier_prefix}${local.department_identifier}"
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.athena_storage_bucket.bucket_id}/${local.department_identifier}/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = var.athena_storage_bucket.kms_key_arn
      }
    }
  }
}