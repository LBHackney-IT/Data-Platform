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
  kms_master_key_id = aws_kms_key.rds_snapshot_to_s3_kms_key.key_id
}

resource "aws_kms_key" "rds_snapshot_to_s3_kms_key" {
  tags = var.tags

  description             = "${var.project} - ${var.environment} - rds-snapshot-to-s3 KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.rds_snapshot_to_s3_kms_key_policy.json
}

data "aws_sns_topic" "rds_snapshot_to_s3" {
  name = "dataplatform-stg-dp-rds-snapshot-to-s3"
}

data "aws_iam_policy_document" "rds_snapshot_to_s3_kms_key_policy" {

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      data.aws_sns_topic.rds_snapshot_to_s3.arn
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.arn,
      ]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    principals {
      identifiers = ["events.rds.amazonaws.com"]
      type        = "Service"
    }

    resources = [
      "arn:aws:rds:eu-west-2:120038763019:db:${var.rds_instance_ids}"
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.arn,
      ]
    }
  }
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
  kms_master_key_id = aws_kms_key.rds_snapshot_to_s3_kms_key.key_id
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
