#===============================================================================
# Management Events Logging (All AWS Services - free)
#===============================================================================

resource "aws_cloudwatch_log_group" "management_events_cloudtrail" {
  name              = "/aws/cloudtrail/${local.identifier_prefix}-management-events"
  retention_in_days = 90

  tags = module.tags.values
}

resource "aws_iam_role" "management_events_cloudtrail_logs_role" {
  name = "${local.identifier_prefix}-management-events-cloudtrail-logs-role"

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

resource "aws_iam_role_policy" "management_events_cloudtrail_logs_policy" {
  name = "${local.identifier_prefix}-management-events-cloudtrail-logs-policy"
  role = aws_iam_role.management_events_cloudtrail_logs_role.id

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
        Resource = "${aws_cloudwatch_log_group.management_events_cloudtrail.arn}:*"
      }
    ]
  })
}

# Summary from AWS Doc and Support:
# 1. For CloudTrail Trails, cannot filter management events by eventSource.
# 2. To log all management events, enable management events (Read/Write).
# 3. We can exclude KMS and RDS Data API events to reduce noise.
# 4. Nearly all of glue operations are management events.
# 5. First copy of management events is free.
resource "aws_cloudtrail" "management_events" {
  name           = "${local.identifier_prefix}-management-events"
  s3_bucket_name = module.cloudtrail_storage.bucket_id
  s3_key_prefix  = "management-events"

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.management_events_cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.management_events_cloudtrail_logs_role.arn

  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true


  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Exclude noisy/high-volume events as recommended by AWS Support
    exclude_management_event_sources = [
      "kms.amazonaws.com",
      "rdsdata.amazonaws.com"
    ]
  }

  tags = module.tags.values

  depends_on = [
    aws_iam_role_policy.management_events_cloudtrail_logs_policy
  ]
}
