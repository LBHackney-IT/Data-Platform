data "aws_caller_identity" "current" {}

locals {
  lambda_timeout = 900
  bucket_source  = "s3://${var.zone_bucket_id}/tascomi/${var.resource_name}_json/"
  bucket_target  = "s3://${var.zone_bucket_id}/tascomi/${var.resource_name}/"
}
