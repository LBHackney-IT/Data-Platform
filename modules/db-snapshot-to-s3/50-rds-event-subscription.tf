data "aws_iam_policy_document" "sns_cloudwatch_logging_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutMetricFilter",
      "logs:PutRetentionPolicy"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "sns_cloudwatch_logging" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-sns-cloudwatch-logging")
  policy = data.aws_iam_policy_document.sns_cloudwatch_logging_policy.json
}

data "aws_iam_policy_document" "sns_cloudwatch_logging_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      identifiers = [
        "sns.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "sns_cloudwatch_logging" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-sns-cloudwatch-logging")
  assume_role_policy = data.aws_iam_policy_document.sns_cloudwatch_logging_assume_role.json
}

resource "aws_iam_policy_attachment" "sns_cloudwatch_policy_attachment" {


  name = lower("${var.identifier_prefix}-sns-cloudwatch-logging-policy")
  roles = [
    aws_iam_role.sns_cloudwatch_logging.name
  ]
  policy_arn = aws_iam_policy.sns_cloudwatch_logging.arn
}

resource "aws_sns_topic" "rds_snapshot_to_s3" {
  tags = var.tags

  name                             = lower("${var.identifier_prefix}-rds-snapshot-to-s3")
  sqs_success_feedback_role_arn    = aws_iam_role.sns_cloudwatch_logging.arn
  sqs_success_feedback_sample_rate = 100
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_cloudwatch_logging.arn
}

resource "aws_db_event_subscription" "snapshot_to_s3" {
  tags = var.tags

  name      = lower("${var.identifier_prefix}-snapshot-to-s3")
  sns_topic = aws_sns_topic.rds_snapshot_to_s3.arn

  source_type = "db-instance"
  source_ids  = var.rds_instance_ids

  event_categories = [
    "backup"
  ]
}