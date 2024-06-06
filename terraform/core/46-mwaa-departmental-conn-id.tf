/*
  Create a new IAM user (department_airflow) and store it with the format of mwaa/airflow connection
  This will be used as aws_conn_id in operators for different departents/teams, e.g. data platform team.
*/

# Define base IAM policy for the permissions shared in all users.
locals {
  logs_policy = {
    Effect = "Allow"
    Action = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:DescribeLogGroups"
    ]
    Resource = "arn:aws:logs:*"
  }

  glue_policy = {
    Effect = "Allow"
    Action = [
      "glue:GetCrawler",
      "glue:GetCrawlerMetrics",
      "glue:GetCrawlers",
      "glue:ListCrawlers",
      "glue:StartCrawler",
      "glue:StopCrawler",
      "glue:UpdateCrawler",
      "glue:UpdateCrawlerSchedule"
    ]
    Resource = "*"
  }

  athena_policy = {
    Effect = "Allow"
    Action = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:ListDatabases",
      "athena:ListTableMetadata",
      "athena:GetTableMetadata"
    ]
    Resource = "*"
  }

  kms_policy = {
    Effect = "Allow"
    Action = [
      "kms:*"
    ]
    Resource = "*"
  }

  base_airflow_policy = {
    Version = "2012-10-17"
    Statement = [
      local.logs_policy,
      local.glue_policy,
      local.athena_policy,
      local.kms_policy
    ]
  }
}

# Define sensitive policy for the permissions of each department's airflow connections
locals {
  # Define the sensitive policy for the child_fam_services department
  child_fam_services_sensitive_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          module.landing_zone.bucket_arn,
          "${module.landing_zone.bucket_arn}/child-fam-services*",
          module.raw_zone.bucket_arn,
          "${module.raw_zone.bucket_arn}/child-fam-services*",
          module.refined_zone.bucket_arn,
          "${module.refined_zone.bucket_arn}/child-fam-services*",
          module.trusted_zone.bucket_arn,
          "${module.trusted_zone.bucket_arn}/child-fam-services*",
          aws_s3_bucket.mwaa_bucket.arn,
          "${aws_s3_bucket.mwaa_bucket.arn}/*"
        ]
      }
      # Add the sensitive policy here
    ]
  }

  child_fam_services_airflow_policy = {
    Version   = local.base_airflow_policy.Version,
    Statement = concat(local.base_airflow_policy.Statement, local.child_fam_services_sensitive_policy.Statement)
  }
}


module "child_fam_services_airflow" {
  source     = "../modules/airflow-departmental-connections"
  department = "child_fam_services_airflow"
  kms_key_id = aws_kms_key.mwaa_key.arn
  policy     = jsonencode(local.child_fam_services_airflow_policy)
  tags       = module.tags.values
}
