/* ==== RAW ZONE ==================================================================================================== */
# TODO: We will be creating a number of different S3 buckets with the same setup. We should consider making a module
resource "aws_kms_key" "raw_zone_key" {
  provider = aws.core
  tags     = module.tags.values

  description             = "${var.project} ${var.environment} - Raw Zone Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "raw_zone_bucket" {
  provider = aws.core
  tags     = module.tags.values

  bucket = lower("${local.identifier_prefix}-raw-zone")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.raw_zone_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "raw_zone_bucket_policy" {
  provider = aws.core

  bucket = aws_s3_bucket.raw_zone_bucket.id
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
          ]
        },
        Action : [
          "s3:ListBucket"
        ],
        Resource : aws_s3_bucket.raw_zone_bucket.arn
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
        Resource : "${aws_s3_bucket.raw_zone_bucket.arn}/social-care/*",
        Condition : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

/* ==== GLUE SCRIPTS ================================================================================================ */
resource "aws_kms_key" "glue_scripts_key" {
  provider = aws.core
  tags     = module.tags.values

  description             = "${var.project} ${var.environment} - Glue Scripts Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "glue_scripts_bucket" {
  provider = aws.core
  tags     = module.tags.values

  bucket = lower("${local.identifier_prefix}-glue-scripts")

//  server_side_encryption_configuration {
//    rule {
//      apply_server_side_encryption_by_default {
//        kms_master_key_id = aws_kms_key.glue_scripts_key.arn
//        sse_algorithm     = "aws:kms"
//      }
//    }
//  }
}

/* ==== GLUE TEMP STORAGE =========================================================================================== */
resource "aws_kms_key" "glue_temp_storage_bucket_key" {
  provider = aws.core
  tags     = module.tags.values

  description             = "${var.project} ${var.environment} - Glue Temp Storage Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "glue_temp_storage_bucket" {
  provider = aws.core
  tags     = module.tags.values

  bucket = lower("${local.identifier_prefix}-glue-temp-storage")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.glue_temp_storage_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

/* ==== ATHENA STORAGE ============================================================================================== */
resource "aws_kms_key" "athena_storage_bucket_key" {
  provider = aws.core
  tags     = module.tags.values

  description             = "${var.project} ${var.environment} - Glue Temp Storage Bucket Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "athena_storage_bucket" {
  provider = aws.core
  tags     = module.tags.values

  bucket = lower("${local.identifier_prefix}-athena-storage")

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.athena_storage_bucket_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}