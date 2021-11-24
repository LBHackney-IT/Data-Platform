resource "aws_s3_bucket_object" "landing_zone_manual_folder" {
  bucket       = var.landing_zone_bucket.bucket_id
  key          = "${local.department_identifier}/manual/"
  content_type = "application/x-directory"
}
