resource "aws_iam_role" "glue_role" {
  tags = module.tags.values

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
          "cloudwatch:PutMetricData",
        ],
        Resource : [
          "*"
        ]
      },
      {
        Effect : "Allow",
        Action : "s3:*",
        Resource : [
          "${module.landing_zone.bucket_arn}/*",
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
      },
      {
        Effect : "Allow",
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
        ],
        Resource : [
          aws_kms_key.glue_scripts_key.arn,
          aws_kms_key.glue_temp_storage_bucket_key.arn,
          aws_kms_key.athena_storage_bucket_key.arn,
          module.landing_zone.kms_key_arn,
          aws_kms_key.sheets_credentials.arn,
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "secretsmanager:GetSecretValue"
        ],
        Resource : [
          aws_secretsmanager_secret.sheets_credentials_housing.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_glue_access_policy_to_glue_role" {
  role = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_access_policy.arn
}

resource "aws_glue_catalog_database" "landing_zone_catalog_database" {
  name = "${local.identifier_prefix}-landing-zone-database"
}

resource "aws_glue_crawler" "landing_zone_bucket_crawler" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.landing_zone_catalog_database.name
  name = "${local.identifier_prefix}-landing-zone-bucket-crawler"
  role = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.landing_zone.bucket_id}"
  }
}
