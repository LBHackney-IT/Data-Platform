#===============================================================================
# Glue Data Catalog Usage Logging
#===============================================================================

resource "aws_cloudwatch_log_group" "glue_data_catalog_cloudtrail" {
  name              = "/aws/cloudtrail/${local.identifier_prefix}-glue-data-catalog"
  retention_in_days = 90

  tags = module.tags.values
}

resource "aws_iam_role" "glue_data_catalog_cloudtrail_logs_role" {
  name = "${local.identifier_prefix}-glue-data-catalog-cloudtrail-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = module.tags.values
}


resource "aws_iam_role_policy" "glue_data_catalog_cloudtrail_logs_policy" {
  name = "${local.identifier_prefix}-glue-data-catalog-cloudtrail-logs-policy"
  role = aws_iam_role.glue_data_catalog_cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.glue_data_catalog_cloudtrail.arn}:*"
      }
    ]
  })
}


resource "aws_cloudtrail" "glue_data_catalog_usage" {
  name           = "${local.identifier_prefix}-glue-data-catalog-usage"
  s3_bucket_name = module.cloudtrail_storage.bucket_id
  s3_key_prefix  = "glue-data-catalog/"

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.glue_data_catalog_cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.glue_data_catalog_cloudtrail_logs_role.arn

  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true

  # Event selectors to capture Glue Data Catalog API calls
  event_selector {
    read_write_type                  = "All"
    include_management_events        = true
    exclude_management_event_sources = []

    # Capture all Glue Data Catalog operations
    data_resource {
      type   = "AWS::Glue::Catalog"
      values = ["arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog"]
    }

    # Capture Glue Database operations
    data_resource {
      type   = "AWS::Glue::Database"
      values = ["arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*"]
    }

    # Capture Glue Table operations
    data_resource {
      type   = "AWS::Glue::Table"
      values = ["arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*"]
    }
  }

  tags = module.tags.values

  depends_on = [
    aws_iam_role_policy.glue_data_catalog_cloudtrail_logs_policy
  ]
}


output "glue_data_catalog_cloudtrail_arn" {
  description = "ARN of the CloudTrail logging Glue Data Catalog usage"
  value       = aws_cloudtrail.glue_data_catalog_usage.arn
}

output "glue_data_catalog_cloudtrail_log_group" {
  description = "CloudWatch Log Group for Glue Data Catalog CloudTrail"
  value       = aws_cloudwatch_log_group.glue_data_catalog_cloudtrail.name
}
