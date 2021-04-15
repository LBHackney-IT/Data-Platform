resource "aws_kms_key" "key" {
  tags = var.tags

  description = "${var.project} ${var.environment} - ${var.bucket_name} Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

resource "aws_s3_bucket" "bucket" {
  tags = var.tags

  bucket = lower("${var.identifier_prefix}-${var.bucket_identifier}")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.key.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid : "ListBucket",
        Effect : "Allow",
        Principal : {
          "AWS" : [
            "arn:aws:iam::261219435789:root",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
          ]
        },
        Action : [
          "s3:ListBucket"
        ],
        Resource : aws_s3_bucket.bucket.arn
      },
      {
        Sid : "AddCannedAcl",
        Effect : "Allow",
        Principal : {
          "AWS" : [
            "arn:aws:iam::261219435789:root",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
          ]
        },
        Action : [
          "s3:PutObject",
          "s3:PutObjectAcl"],
        Resource : "${aws_s3_bucket.bucket.arn}/social-care/*",
        Condition : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      },
      {
        Sid : "AddCannedAcl",
        Effect : "Allow",
        Principal : {
          "AWS" : [
            "arn:aws:iam::261219435789:root",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
          ]
        },
        Action : [
          "s3:PutObject",
          "s3:PutObjectAcl"],
        Resource : "${aws_s3_bucket.bucket.arn}/housing/*",
        Condition : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      },
      {
        Sid : "AddCannedAcl",
        Effect : "Allow",
        Principal : {
          "AWS" : [
            "arn:aws:iam::261219435789:root",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463",
          ]
        },
        Action : [
          "s3:GetObject"],
        Resource : [
          "${aws_s3_bucket.bucket.arn}/social-care/*",
          "${aws_s3_bucket.bucket.arn}/social-care/*",
          "${aws_s3_bucket.bucket.arn}/social-care/*",
          "${aws_s3_bucket.bucket.arn}/social-care/*",
        ],
        Condition : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
