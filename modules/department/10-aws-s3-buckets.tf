//resource "aws_s3_bucket_object" "landing_zone_department_folder" {
//  bucket       = var.landing_zone_bucket_id
//  acl          = "private"
//  key          = "${local.identifier}/"
//  content_type = "application/x-directory"
//}
//
//resource "aws_s3_bucket_object" "raw_zone_department_folder" {
//  bucket       = var.raw_zone_bucket_id
//  acl          = "private"
//  key          = "${local.identifier}/"
//  content_type = "application/x-directory"
//}
//
//resource "aws_s3_bucket_object" "refined_zone_department_folder" {
//  bucket       = var.refined_zone_bucket_id
//  acl          = "private"
//  key          = "${local.identifier}/"
//  content_type = "application/x-directory"
//}
//
//resource "aws_s3_bucket_object" "trusted_zone_department_folder" {
//  bucket       = var.trusted_zone_bucket_id
//  acl          = "private"
//  key          = "${local.identifier}/"
//  content_type = "application/x-directory"
//}