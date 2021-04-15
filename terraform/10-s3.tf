resource "aws_kms_key" "a" {
  description = "Data Platform - Raw Data KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation = true
}

resource "aws_s3_bucket" "data_platform_raw" {
  provider = aws.core
  bucket = "hackney-data-platform-raw-staging-mtsandbox"
}

resource "aws_s3_bucket" "data_platform_glue_script" {
  provider = aws.core
  bucket = "hackney-data-platform-glue-script"
}

resource "aws_s3_bucket_object" "google_sheets_import_script" {
  provider = aws.core
  bucket = aws_s3_bucket.data_platform_glue_script.id
  key    = "scripts/google-sheets-import.py"
  acl    = "private"
  source = "../scripts/google-sheets-import.py"
  etag = filemd5("../scripts/google-sheets-import.py")
}

resource "aws_s3_bucket" "data_platform_glue_temp_storage" {
  provider = aws.core
  bucket = "hackney-data-platform-glue-temp-storage"
}

resource "aws_iam_role" "glue" {
  provider = aws.core
  name = "data-platform-glue-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: "glue.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  })
}

resource "aws_iam_policy" "glue_access_policy" {
  provider = aws.core
  name = "data-platform-glue-access-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        Effect: "Allow",
        Action: [
          "glue:*",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "cloudwatch:PutMetricData"
        ],
        Resource: [
          "*"
        ]
      },
      {
        Effect: "Allow",
        Action: "s3:*",
        Resource: [
          "${aws_s3_bucket.data_platform_raw.arn}/*",
          "${aws_s3_bucket.data_platform_glue_temp_storage.arn}/*",
          "${aws_s3_bucket.data_platform_glue_script.arn}/*"
        ]
      },
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:AssociateKmsKey"
        ],
        Resource: [
          "arn:aws:logs:*:*:/aws-glue/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_glue_access_policy" {
  provider = aws.core
  role = aws_iam_role.glue.name
  policy_arn = aws_iam_policy.glue_access_policy.arn
}

resource "aws_s3_bucket_policy" "data_platform_raw_bucket_policy" {
  provider = aws.core
  bucket = aws_s3_bucket.data_platform_raw.id
  policy = jsonencode({
    "Version":"2012-10-17",
    "Statement":[
      {
        Sid:"ListBucket",
        Effect:"Allow",
        Principal: {
          "AWS": [
            "arn:aws:iam::261219435789:root",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"]
        },
        Action:[
          "s3:ListBucket"],
        Resource:aws_s3_bucket.data_platform_raw.arn
      },
      {
        Sid:"AddCannedAcl",
        Effect:"Allow",
        Principal: {
          "AWS": [
            "arn:aws:iam::261219435789:root",
            "arn:aws:iam::261219435789:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_SandboxAdmin_772511f048f85463"]
        },
        Action:[
          "s3:PutObject",
          "s3:PutObjectAcl"],
        Resource:"${aws_s3_bucket.data_platform_raw.arn}/social-care/*",
        Condition: {
          "StringEquals": {
            "s3:x-amz-acl": "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_object" "test_folder" {
  provider = aws.core
  bucket = aws_s3_bucket.data_platform_raw.id
  acl    = "private"
  key    = "test/"
  source = "/dev/null"
}

resource "aws_glue_job" "google_sheet_import_glue_job" {
  provider = aws.core
  name     = "Google Sheets Import Job"
  role_arn = aws_iam_role.glue.arn
  command {
    python_version = "3"
    script_location = "s3://${aws_s3_bucket.data_platform_glue_script.id}/${aws_s3_bucket_object.google_sheets_import_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--TempDir" = "s3://${aws_s3_bucket.data_platform_glue_temp_storage.id}"
    "--additional-python-modules" = "gspread==3.7.0, google-auth==1.27.1, pyspark==3.1.1"
    "--s3_bucket_target" = "s3://${aws_s3_bucket.data_platform_raw.id}/${aws_s3_bucket_object.test_folder.key}"
  }
}

resource "aws_glue_catalog_database" "raw_catalog_database" {
  provider = aws.core
  name = "raw-bucket-database"
}

resource "aws_glue_crawler" "raw_bucket_crawler" {
  provider = aws.core
  database_name = aws_glue_catalog_database.raw_catalog_database.name
  name          = "data-platform-raw-bucket-crawler"
  role          = aws_iam_role.glue.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_platform_raw.bucket}"
  }
}

resource "aws_s3_bucket" "athena_query_result_location" {
  provider = aws.core
  bucket = "hackney-data-platform-athena-query-result-location"
}

resource "aws_athena_database" "raw-bucket-athena-database" {
  provider = aws.core
  name   = "data_platform_raw_bucket_athena_database"
  bucket = aws_s3_bucket.athena_query_result_location.bucket
}
