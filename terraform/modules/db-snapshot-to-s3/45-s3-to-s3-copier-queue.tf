resource "aws_sqs_queue" "s3_to_s3_copier" {
  tags = var.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.s3_to_s3_copier_deadletter.arn
    maxReceiveCount     = 4
  })

  // To allow your function time to process each batch of records, set the source queue's visibility timeout to at
  // least 6 times the timeout that you configure on your function. The extra time allows for Lambda to retry if your
  // function execution is throttled while your function is processing a previous batch.
  // See: https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html
  visibility_timeout_seconds = local.lambda_timeout * 6

  name              = lower("${var.identifier_prefix}-s3-to-s3-copier")
  kms_master_key_id = var.rds_export_storage_kms_key_id
}

resource "aws_kms_key" "s3_to_s3_copier_kms_key" {
  tags = var.tags

  description             = "${var.project} - ${var.environment} - s3-to-s3-copier KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.s3_to_s3_copier_kms_key_policy.json
}

data "aws_iam_policy_document" "s3_to_s3_copier_kms_key_policy" {

  statement {
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "s3_to_s3_copier" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes"
    ]
    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
    resources = [
      aws_sqs_queue.s3_to_s3_copier.arn
    ]
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      aws_kms_key.s3_to_s3_copier_kms_key.arn,
    ]
  }
}

resource "aws_sqs_queue_policy" "s3_copier_to_s3" {
  queue_url = aws_sqs_queue.s3_to_s3_copier.id
  policy    = data.aws_iam_policy_document.s3_to_s3_copier.json
}

resource "aws_sqs_queue" "s3_to_s3_copier_deadletter" {
  tags = var.tags

  name              = lower("${var.identifier_prefix}-s3-to-s3-copier-deadletter")
  kms_master_key_id = aws_kms_key.s3_to_s3_copier_kms_key.key_id
}

resource "aws_lambda_event_source_mapping" "s3_to_s3_copier_mapping" {

  event_source_arn = aws_sqs_queue.s3_to_s3_copier.arn
  enabled          = true
  function_name    = aws_lambda_function.s3_to_s3_copier_lambda.arn
  batch_size       = 1
}
