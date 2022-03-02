resource "aws_kms_key" "kms_key" {
  tags = module.tags.values

  description             = "${var.project} - ${var.environment} KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "terraform_state_storage" {
  tags = module.tags.values

  bucket = lower("${var.project}-terraform-state")
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_storage" {
  bucket = aws_s3_bucket.terraform_state_storage.id
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
