resource "aws_sqs_queue" "rds_snapshot_to_s3" {

  tags = var.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.rds_snapshot_to_s3_deadletter.arn
    maxReceiveCount     = 4
  })

  // To allow your function time to process each batch of records, set the source queue's visibility timeout to at
  // least 6 times the timeout that you configure on your function. The extra time allows for Lambda to retry if your
  // function execution is throttled while your function is processing a previous batch.
  // See: https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html
  visibility_timeout_seconds = local.lambda_timeout * 6

  name              = lower("${var.identifier_prefix}-rds-snapshot-to-s3")
  kms_master_key_id = aws_kms_key.kms_key.id
}

resource "aws_kms_key" "kms_key" {
  tags = var.tags

  description             = "${var.project} - ${var.environment} - rds-snapshot-to-s3 KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
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

  name              = lower("${var.identifier_prefix}-rds-snapshot-to-s3-deadletter")
  kms_master_key_id = aws_kms_key.kms_key.id
}

resource "aws_kms_key" "kms_key" {
  tags = var.tags

  description             = "${var.project} - ${var.environment} - rds-snapshot-to-s3-deadletter KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
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
