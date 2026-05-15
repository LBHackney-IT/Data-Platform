# Workflow overview:
# - This staging-only Terraform creates the AWS CodeConnections, CodeBuild, IAM, and CloudWatch Logs
#   resources needed to sync the `dap-airflow` GitHub repository into the staging MWAA buckets.
# - When code is pushed to the `staging` branch in `dap-airflow`, a GitHub Actions workflow starts
#   this CodeBuild project explicitly.
# - CodeBuild pulls the repository by using the AWS CodeConnections connection defined in this file.
# - The build runs `github_workflow_scripts/mwaa-s3-sync-buildspec.yml` from the `dap-airflow` repository.
# - That build syncs the Airflow DAGs folder and the ETL scripts folder into the staging MWAA S3 buckets.
# - The result is that the `stg` MWAA environment stays in sync with the latest `staging` branch code.
#
# Operational note:
# - The CodeBuild project is intentionally not connected to GitHub with a native CodeBuild webhook.
# - The staging GitHub Actions workflow starts CodeBuild only for pushes to the `staging` branch.
# - This avoids PR, main, and autofix commits being sent to the CodeBuild webhook endpoint.

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

resource "aws_iam_role_policy" "github_actions_start_dap_airflow_codebuild_sync" {
  count = local.environment == "stg" ? 1 : 0

  name = "${local.identifier_prefix}-github-actions-start-dap-airflow-sync"
  role = var.aws_deploy_iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = aws_codebuild_project.dap_airflow_staging_sync[0].arn
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
