# Workflow overview:
# - This staging-only Terraform creates the AWS CodeConnections, CodeBuild, IAM, CloudWatch Logs,
#   and webhook resources needed to sync the `dap-datahub-tools` GitHub repository into the staging
#   DataHub ingestion bucket.
# - When code is pushed to the `staging` branch in `dap-datahub-tools`, the CodeBuild webhook starts a build.
# - CodeBuild pulls the repository by using the AWS CodeConnections connection defined in this file.
# - The build runs `github_workflow_scripts/datahub-tools-s3-sync-buildspec.yaml` from the
#   `dap-datahub-tools` repository.
# - That build syncs the DataHub YAML config and ETL scripts folders into the staging DataHub ingestion bucket.
# - The result is that the `stg` DataHub ingestion bucket can be tested with the latest `staging` branch code.

resource "aws_codestarconnections_connection" "dap_datahub_tools_stg" {
  count = local.environment == "stg" ? 1 : 0

  name          = "${local.identifier_prefix}-dap-datahub-tools"
  provider_type = "GitHub"
  tags          = module.tags.values
}

resource "aws_iam_role" "codebuild_dap_datahub_tools_staging_role" {
  count = local.environment == "stg" ? 1 : 0

  name = "${local.identifier_prefix}-codebuild-dap-datahub-tools-sync-role"

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

resource "aws_iam_role_policy" "codebuild_dap_datahub_tools_staging_policy" {
  count = local.environment == "stg" ? 1 : 0

  name = "${local.identifier_prefix}-codebuild-dap-datahub-tools-sync-policy"
  role = aws_iam_role.codebuild_dap_datahub_tools_staging_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = module.datahub_ingestion.bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ]
        Resource = "${module.datahub_ingestion.bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = module.datahub_ingestion.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_deploy_region}:${var.aws_deploy_account_id}:log-group:/aws/codebuild/${local.identifier_prefix}-dap-datahub-tools-sync:*"
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
        Resource = "arn:aws:codebuild:${var.aws_deploy_region}:${var.aws_deploy_account_id}:report-group/${local.identifier_prefix}-dap-datahub-tools-sync*"
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
        Resource = aws_codestarconnections_connection.dap_datahub_tools_stg[0].arn
      }
    ]
  })
}

resource "aws_codebuild_project" "dap_datahub_tools_staging_sync" {
  count = local.environment == "stg" ? 1 : 0

  name           = "${local.identifier_prefix}-dap-datahub-tools-sync"
  description    = "Sync dap-datahub-tools repository folders to the DataHub ingestion S3 bucket for staging"
  service_role   = aws_iam_role.codebuild_dap_datahub_tools_staging_role[0].arn
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

    environment_variable {
      name  = "DATAHUB_INGESTION_BUCKET"
      value = module.datahub_ingestion.bucket_id
    }

    environment_variable {
      name  = "SOURCE_REPO"
      value = "dap-datahub-tools"
    }
  }

  source {
    type                = "GITHUB"
    location            = "https://github.com/LBHackney-IT/dap-datahub-tools.git"
    git_clone_depth     = 1
    buildspec           = "github_workflow_scripts/datahub-tools-s3-sync-buildspec.yaml" # Stored in dap-datahub-tools repo
    report_build_status = false

    auth {
      type     = "CODECONNECTIONS"
      resource = aws_codestarconnections_connection.dap_datahub_tools_stg[0].arn
    }
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.codebuild_dap_datahub_tools_staging[0].name
      stream_name = "staging"
    }
  }

  tags = module.tags.values
}

resource "aws_cloudwatch_log_group" "codebuild_dap_datahub_tools_staging" {
  count = local.environment == "stg" ? 1 : 0

  name              = "/aws/codebuild/${local.identifier_prefix}-dap-datahub-tools-sync"
  retention_in_days = 30
  tags              = module.tags.values
}

resource "aws_codebuild_webhook" "dap_datahub_tools_staging_webhook" {
  count = local.environment == "stg" ? 1 : 0

  project_name = aws_codebuild_project.dap_datahub_tools_staging_sync[0].name
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
