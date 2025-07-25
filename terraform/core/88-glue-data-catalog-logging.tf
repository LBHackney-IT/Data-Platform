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

  # Use advanced_event_selector for comprehensive Glue Data Catalog logging
  # because event_selector only supports data_resource field includes only S3, Dynamodb, Lambda events
  advanced_event_selector {
    name = "Log Glue Data Catalog events only"
    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
    field_selector {
      field  = "eventSource"
      equals = ["glue.amazonaws.com"]
    }
    field_selector {
      field = "eventName"
      equals = [
        # Database operations
        "CreateDatabase", "GetDatabase", "GetDatabases", "UpdateDatabase", "DeleteDatabase",
        # Table operations
        "CreateTable", "GetTable", "GetTables", "UpdateTable", "DeleteTable",
        "GetTableVersion", "GetTableVersions", "DeleteTableVersion",
        # Partition operations
        "CreatePartition", "GetPartition", "GetPartitions", "UpdatePartition", "DeletePartition",
        "GetPartitionIndexes", "CreatePartitionIndex", "DeletePartitionIndex"
      ]
    }
  }
  tags = module.tags.values

  depends_on = [
    aws_iam_role_policy.glue_data_catalog_cloudtrail_logs_policy
  ]
}
