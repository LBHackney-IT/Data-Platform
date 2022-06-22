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

  name = lower("${var.identifier_prefix}-s3-to-s3-copier")
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
}

resource "aws_sqs_queue_policy" "s3_copier_to_s3" {
  queue_url = aws_sqs_queue.s3_to_s3_copier.id
  policy    = data.aws_iam_policy_document.s3_to_s3_copier.json
}

resource "aws_sqs_queue" "s3_to_s3_copier_deadletter" {
  tags = var.tags

  name = lower("${var.identifier_prefix}-s3-to-s3-copier-deadletter")
}

resource "aws_lambda_event_source_mapping" "s3_to_s3_copier_mapping" {

  event_source_arn = aws_sqs_queue.s3_to_s3_copier.arn
  enabled          = true
  function_name    = aws_lambda_function.s3_to_s3_copier_lambda.arn
  batch_size       = 1
}
