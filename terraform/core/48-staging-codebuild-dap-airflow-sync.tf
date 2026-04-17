# Workflow overview:
# - This staging-only Terraform creates the AWS CodeConnections, CodeBuild, IAM, CloudWatch Logs,
#   and webhook resources needed to sync the `dap-airflow` GitHub repository into the staging MWAA buckets.
# - When code is pushed to the `staging` branch in `dap-airflow`, the CodeBuild webhook starts a build.
# - CodeBuild pulls the repository by using the AWS CodeConnections connection defined in this file.
# - The build runs `github_workflow_scripts/mwaa-s3-sync-buildspec.yml` from the `dap-airflow` repository.
# - That build syncs the Airflow DAGs folder and the ETL scripts folder into the staging MWAA S3 buckets.
# - The result is that the `stg` MWAA environment stays in sync with the latest `staging` branch code.
#
# Operational note for rotating webhook secret:
# - If this is required, DP or CE only needs to delete the existing CodeBuild webhook from AWS.
# - The webhook can be deleted by using either the AWS CLI or the AWS Console.
# - Then redeploy this Terraform workflow and it will recreate the webhook with the updated webhook secret.
# - The AWS CodeConnections resource does not need to be deleted or re-approved.

resource "aws_codestarconnections_connection" "dap_airflow_stg" {
  count = local.environment == "stg" ? 1 : 0

  name          = "${local.identifier_prefix}-dap-airflow"
  provider_type = "GitHub"
  tags          = module.tags.values
}

resource "aws_iam_role" "codebuild_dap_airflow_staging_role" {
  count = local.environment == "stg" ? 1 : 0

  name = "${local.identifier_prefix}-codebuild-dap-airflow-sync-role"

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

  name = "${local.identifier_prefix}-codebuild-dap-airflow-sync-policy"
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
        Resource = "arn:aws:logs:${var.aws_deploy_region}:${var.aws_deploy_account_id}:log-group:/aws/codebuild/${local.identifier_prefix}-dap-airflow-sync:*"
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
        Resource = "arn:aws:codebuild:${var.aws_deploy_region}:${var.aws_deploy_account_id}:report-group/${local.identifier_prefix}-dap-airflow-sync*"
      },
      {
        Sid    = "AllowCodeStarAndCodeConnectionsAccess"
        Effect = "Allow"
        Action = [
          "codestar-connections:GetConnection",
          "codestar-connections:GetConnectionToken",
          "codestar-connections:UseConnection",
          "codeconnections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.dap_airflow_stg[0].arn
      }
    ]
  })
}

resource "aws_codebuild_project" "dap_airflow_staging_sync" {
  count = local.environment == "stg" ? 1 : 0

  name           = "${local.identifier_prefix}-dap-airflow-sync"
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
    report_build_status = false

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codestarconnections_connection.dap_airflow_stg[0].arn
    }
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.codebuild_dap_airflow_staging[0].name
      stream_name = "staging"
    }
  }

  tags = module.tags.values
}

resource "aws_cloudwatch_log_group" "codebuild_dap_airflow_staging" {
  count = local.environment == "stg" ? 1 : 0

  name              = "/aws/codebuild/${local.identifier_prefix}-dap-airflow-sync"
  retention_in_days = 30
  tags              = module.tags.values
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
