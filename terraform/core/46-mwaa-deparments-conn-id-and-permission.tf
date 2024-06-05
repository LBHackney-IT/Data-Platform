/*
  Create a new IAM user (department_airflow) and store it with the format of mwaa/airflow connection
  This will be used as aws_conn_id in operators for different departents/teams, e.g. data platform team.
*/

# Define IAM policies for the permissions of each department's airflow connections
locals {
  dataplatform_airflow_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          module.landing_zone.bucket_arn,
          "${module.landing_zone.bucket_arn}/*",
          module.raw_zone.bucket_arn,
          "${module.raw_zone.bucket_arn}/*",
          module.refined_zone.bucket_arn,
          "${module.refined_zone.bucket_arn}/*",
          module.trusted_zone.bucket_arn,
          "${module.trusted_zone.bucket_arn}/*",
          aws_s3_bucket.mwaa_bucket.arn,
          "${aws_s3_bucket.mwaa_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults",
          "logs:DescribeLogGroups"
        ],
        Resource = "arn:aws:logs:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "glue:CreateCrawler",
          "glue:DeleteCrawler",
          "glue:GetCrawler",
          "glue:GetCrawlerMetrics",
          "glue:GetCrawlers",
          "glue:ListCrawlers",
          "glue:StartCrawler",
          "glue:StopCrawler",
          "glue:UpdateCrawler",
          "glue:UpdateCrawlerSchedule"
        ],
        "Resource" : "*"
      },
      {
        Effect = "Allow",
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:ListDatabases",
          "athena:ListTableMetadata",
          "athena:GetTableMetadata"
        ],
        Resource = "*"
      },
    ]
  })

  parking_airflow_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          module.landing_zone.bucket_arn,
          "${module.landing_zone.bucket_arn}/*",
          module.raw_zone.bucket_arn,
          "${module.raw_zone.bucket_arn}/*",
          module.refined_zone.bucket_arn,
          "${module.refined_zone.bucket_arn}/*",
          module.trusted_zone.bucket_arn,
          "${module.trusted_zone.bucket_arn}/*",
          aws_s3_bucket.mwaa_bucket.arn,
          "${aws_s3_bucket.mwaa_bucket.arn}/*"
        ]
      }
      # An example, Add the rest of the permissions
    ]
  })
}

module "dataplatform_airflow" {
  source     = "../modules/airflow-depermental-connections"
  department = "dataplatform_airflow"
  kms_key_id = aws_kms_key.mwaa_key.arn
  policy     = local.dataplatform_airflow_policy
  tags       = module.tags.values
}

module "parking_airflow" {
  source     = "../modules/airflow-depermental-connections"
  department = "parking_airflow"
  kms_key_id = aws_kms_key.mwaa_key.arn
  policy     = local.parking_airflow_policy
  tags       = module.tags.values
}
