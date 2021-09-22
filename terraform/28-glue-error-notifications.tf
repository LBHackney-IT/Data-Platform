locals {
  email = "ben.dalton@madetech.com"
  lambda_timeout = 900
}
//
resource "aws_sns_topic" "glue_jobs" {
  tags = module.tags.values
  name = "here-to-help-data-ingestion"
}
//
//// use SQS queue??
//
//resource "aws_sns_topic_subscription" "here-to-help-data-ingestion-email-subscription" {
//  topic_arn = aws_sns_topic.glue_jobs.arn
//  protocol  = "email"
//  endpoint  = local.email
//}

data "archive_file" "glue_job_error_notification_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/glue-error-notifications"
  output_path = "../lambdas/glue-error-notifications.zip"
}

resource "aws_s3_bucket_object" "glue_job_error_notification_lambda" {
  tags = module.tags.values

  bucket = module.lambda_artefact_storage.bucket_id
  key    = "glue-error-notifications.zip"
  source = data.archive_file.glue_job_error_notification_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.glue_job_error_notification_lambda.output_md5
}

resource "aws_lambda_function" "glue_error_notification_lambda" {
  tags = module.tags.values

  role             = aws_iam_role.glue_error_notification_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${local.short_identifier_prefix}glue-error-notification"
  s3_bucket        = module.lambda_artefact_storage.bucket_id
  s3_key           = aws_s3_bucket_object.glue_job_error_notification_lambda.key
  source_code_hash = data.archive_file.glue_job_error_notification_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.glue_jobs.arn
    }
  }
}

data "aws_iam_policy_document" "glue_error_notification_lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "glue_error_notification_lambda" {
  tags = module.tags.values

  name               = lower("${local.short_identifier_prefix}glue-error-notification-lambda")
  assume_role_policy = data.aws_iam_policy_document.glue_error_notification_lambda_assume_role.json
}

data "aws_iam_policy_document" "glue_error_notification_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "SNS:Publish"
    ]
    effect = "Allow"
    resources = [
      aws_sns_topic.glue_jobs.arn
    ]
  }
}

resource "aws_iam_policy" "glue_error_notification_lambda" {
  tags = module.tags.values

  name   = lower("${local.short_identifier_prefix}glue-error-notification-lambda")
  policy = data.aws_iam_policy_document.glue_error_notification_lambda.json
}

resource "aws_iam_role_policy_attachment" "glue_error_notification_lambda" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_error_notification_lambda.arn
}

resource "aws_cloudwatch_event_rule" "glue_error_notification_event_rule" {
  name = "${local.short_identifier_prefix}glue-job-fail"
  description = "Raise event when a glue job fails"
  event_pattern = <<EOF
  {
      "detail-type": [
        "Glue Job State Change"
      ],
      "source": [
        "aws.glue"
      ],
      "detail": {
        "state": [
          "FAILED"
        ]
      }
    }
  EOF
}

resource "aws_cloudwatch_event_target" "glue_job_error_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.glue_error_notification_event_rule.name
  arn = aws_lambda_function.glue_error_notification_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_error_notification_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_error_notification_event_rule.arn
}
