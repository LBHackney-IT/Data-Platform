resource "aws_s3_object" "landing_zone_department_folder" {
  bucket       = var.landing_zone_bucket.bucket_id
  acl          = "private"
  key          = "${local.department_identifier}/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "landing_zone_department_folder_manual" {
  bucket       = var.landing_zone_bucket.bucket_id
  acl          = "private"
  key          = "${local.department_identifier}/manual/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "raw_zone_department_folder" {
  bucket       = var.raw_zone_bucket.bucket_id
  acl          = "private"
  key          = "${local.department_identifier}/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "refined_zone_department_folder" {
  bucket       = var.refined_zone_bucket.bucket_id
  acl          = "private"
  key          = "${local.department_identifier}/"
  content_type = "application/x-directory"
}

resource "aws_s3_object" "trusted_zone_department_folder" {
  bucket       = var.trusted_zone_bucket.bucket_id
  acl          = "private"
  key          = "${local.department_identifier}/"
  content_type = "application/x-directory"
}
