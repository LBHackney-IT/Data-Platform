# We add AWS resources to a .tf folder

module "s3_bucket_example" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.s3_bucket_name
  acl    = "private"

  versioning = {
    enabled = true
  }
  
  tags = module.tags.values
}
