resource "aws_iam_role" "glue_role" {
  provider = aws.core
  tags     = module.tags.values

  name = "${local.identifier_prefix}-glue-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "glue.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_policy" "glue_access_policy" {
  provider = aws.core

  name = "${local.identifier_prefix}-glue-access-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect : "Allow",
        Action : [
          "glue:*",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "cloudwatch:PutMetricData"
        ],
        Resource : [
          "*"
        ]
      },
      {
        Effect : "Allow",
        Action : "s3:*",
        Resource : [
          "${aws_s3_bucket.raw_zone_bucket.arn}/*",
          "${aws_s3_bucket.glue_scripts_bucket.arn}/*",
          "${aws_s3_bucket.glue_temp_storage_bucket.arn}/*"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:AssociateKmsKey"
        ],
        Resource : [
          "arn:aws:logs:*:*:/aws-glue/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_glue_access_policy_to_glue_role" {
  provider = aws.core

  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_access_policy.arn
}

resource "aws_glue_catalog_database" "raw_zone_catalog_database" {
  provider = aws.core

  name = "${local.identifier_prefix}-raw-zone-database"
}

resource "aws_glue_crawler" "raw_zone_bucket_crawler" {
  provider = aws.core
  tags     = module.tags.values

  database_name = aws_glue_catalog_database.raw_zone_catalog_database.name
  name          = "${local.identifier_prefix}-raw-zone-bucket-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.raw_zone_bucket.bucket}"
  }
}