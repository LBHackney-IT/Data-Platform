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
