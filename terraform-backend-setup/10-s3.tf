resource "aws_kms_key" "tfbackend" {
  provider = aws.core
  description = "${var.project} - ${var.environment} KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

resource "aws_s3_bucket" "data_platform_terraform_backend" {
  provider = aws.core
  bucket = lower("${var.team}-${var.project}-${var.environment}-tfstate")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tfbackend.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
