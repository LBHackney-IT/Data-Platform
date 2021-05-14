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

resource "aws_sqs_queue" "rds_snapshot_to_s3" {

  tags = var.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.rds_snapshot_to_s3_deadletter.arn
    maxReceiveCount     = 4
  })

  name = lower("${var.identifier_prefix}-rds-snapshot-to-s3")
}

data "aws_iam_policy_document" "rds_snapshot_to_s3" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.rds_snapshot_to_s3.arn]
      variable = "aws:SourceArn"
    }
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      aws_sqs_queue.rds_snapshot_to_s3.arn
    ]
  }
}

resource "aws_sqs_queue_policy" "rds_snapshot_to_s3" {

  queue_url = aws_sqs_queue.rds_snapshot_to_s3.id
  policy    = data.aws_iam_policy_document.rds_snapshot_to_s3.json
}

resource "aws_sqs_queue" "rds_snapshot_to_s3_deadletter" {

  tags = var.tags

  name = lower("${var.identifier_prefix}-rds-snapshot-to-s3-deadletter")
}

resource "aws_sns_topic_subscription" "subscribe_sqs_to_sns_topic" {


  topic_arn = aws_sns_topic.rds_snapshot_to_s3.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.rds_snapshot_to_s3.arn
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {


  event_source_arn = aws_sqs_queue.rds_snapshot_to_s3.arn
  enabled          = true
  function_name    = aws_lambda_function.rds_snapshot_to_s3_lambda.arn
  batch_size       = 1
}
