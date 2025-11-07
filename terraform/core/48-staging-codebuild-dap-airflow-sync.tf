# Staging CodeBuild integration that syncs dap-airflow repository two folders to two MWAA S3 buckets.

resource "aws_codestarconnections_connection" "dap_airflow_stg" {
  count = local.environment == "stg" ? 1 : 0

  name          = "${local.identifier_prefix}-stg-dap-airflow-connection"
  provider_type = "GitHub"
  tags          = module.tags.values
}

resource "aws_iam_role" "codebuild_dap_airflow_staging_role" {
  count = local.environment == "stg" ? 1 : 0

  name = "${local.identifier_prefix}-stg-codebuild-dap-airflow-sync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = module.tags.values
}

resource "aws_iam_role_policy" "codebuild_dap_airflow_staging_policy" {
  count = local.environment == "stg" ? 1 : 0

  name = "${local.identifier_prefix}-stg-codebuild-dap-airflow-sync-policy"
  role = aws_iam_role.codebuild_dap_airflow_staging_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.mwaa_bucket.arn,
          "${aws_s3_bucket.mwaa_bucket.arn}/*",
          aws_s3_bucket.mwaa_etl_scripts_bucket.arn,
          "${aws_s3_bucket.mwaa_etl_scripts_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.mwaa_key.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_deploy_region}:${var.aws_deploy_account_id}:log-group:/aws/codebuild/${local.identifier_prefix}-stg-dap-airflow-sync:*"
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:CreateReport",
          "codebuild:CreateReportGroup",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
        Resource = "arn:aws:codebuild:${var.aws_deploy_region}:${var.aws_deploy_account_id}:report-group/${local.identifier_prefix}-stg-dap-airflow-sync*"
      },
      {
        Effect   = "Allow"
        Action   = "codestar-connections:UseConnection"
        Resource = aws_codestarconnections_connection.dap_airflow_stg[0].arn
      }
    ]
  })
}

resource "aws_codebuild_project" "dap_airflow_staging_sync" {
  count = local.environment == "stg" ? 1 : 0

  name           = "${local.identifier_prefix}-stg-dap-airflow-sync"
  description    = "Sync dap-airflow repository folders to MWAA S3 buckets for staging"
  service_role   = aws_iam_role.codebuild_dap_airflow_staging_role[0].arn
  badge_enabled  = false
  build_timeout  = 5  # 5 minutes (default is 60 minutes)
  queued_timeout = 30 # 30 minutes (default is 480 minutes)

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL" # Smallest type
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type                = "GITHUB"
    location            = "https://github.com/LBHackney-IT/dap-airflow.git"
    git_clone_depth     = 1
    buildspec           = "github_workflow_scripts/mwaa-s3-sync-buildspec.yml" # Stored in dap-airflow repo
    report_build_status = true

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codestarconnections_connection.dap_airflow_stg[0].arn
    }
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = "/aws/codebuild/${local.identifier_prefix}-stg-dap-airflow-sync"
      stream_name = "staging"
    }
  }

  tags = module.tags.values
}

resource "aws_codebuild_webhook" "dap_airflow_staging_webhook" {
  count = local.environment == "stg" ? 1 : 0

  project_name = aws_codebuild_project.dap_airflow_staging_sync[0].name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "^refs/heads/staging$"
    }
  }
}
