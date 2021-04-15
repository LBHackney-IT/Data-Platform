resource "aws_s3_bucket" "service_api_qlik" {
  provider = aws.core

  bucket = format("social-care-case-viewer-api-qlik-bucket-%s", lower(var.environment))

  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  replication_configuration {
    role = aws_iam_role.service_api_qlik_replica.arn

    rules {
      id     = format("social-care-case-viewer-api-qlik-bucket-%s-rule", lower(var.environment))
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.service_api_qlik_replica.arn
        storage_class = "STANDARD"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = module.tags.values
}

resource "aws_s3_bucket_public_access_block" "service_api_qlik" {
  provider = aws.core

  bucket = aws_s3_bucket.service_api_qlik.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "service_api_qlik_allow_ssl_only" {
  provider = aws.core

  bucket = aws_s3_bucket.service_api_qlik.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowSSLRequestsOnly",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": [
          aws_s3_bucket.service_api_qlik.arn,
          "${aws_s3_bucket.service_api_qlik.arn}/*",
        ],
        "Condition": {
          "Bool": {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

resource "aws_ssm_parameter" "service_api_qlik_bucket_name" {
  provider = aws.core

  name  = format("/social-care-postgresql-import/mosaic-%s/bucket-name", lower(var.environment))
  type  = "String"
  value = aws_s3_bucket.service_api_qlik.bucket

  tags = module.tags.values
}

resource "aws_ssm_parameter" "service_api_qlik_bucket_allocations_filename" {
  provider = aws.core

  name  = format("/social-care-postgresql-import/mosaic-%s/allocations-import-filename", lower(var.environment))
  type  = "String"
  value = "CFS_allocations.csv"

  tags = module.tags.values
}
