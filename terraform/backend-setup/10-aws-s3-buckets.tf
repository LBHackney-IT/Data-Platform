resource "aws_kms_key" "kms_key" {
  tags = module.tags.values

  description             = "${var.project} - ${var.environment} KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "terraform_state_storage" {
  tags = merge(module.tags.values, { S3Backup = true })

  bucket = lower("${var.project}-terraform-state")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket     = aws_s3_bucket.terraform_state_storage.id
  depends_on = [aws_s3_bucket.terraform_state_storage]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
