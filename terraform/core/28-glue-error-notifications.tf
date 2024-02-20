locals {
  lambda_timeout = 900
}

data "archive_file" "glue_job_failure_notification_lambda" {
  type        = "zip"
  source_dir  = "../../lambdas/glue-failure-notifications"
  output_path = "../../lambdas/glue-failure-notifications.zip"
}

resource "aws_s3_object" "glue_job_failure_notification_lambda" {
  bucket      = module.lambda_artefact_storage.bucket_id
  key         = "glue-failure-notifications.zip"
  source      = data.archive_file.glue_job_failure_notification_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.glue_job_failure_notification_lambda.output_md5
}

resource "aws_lambda_function" "glue_failure_notification_lambda" {
  tags = module.tags.values

  role             = aws_iam_role.glue_failure_notification_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${local.short_identifier_prefix}glue-failure-notification"
  s3_bucket        = module.lambda_artefact_storage.bucket_id
  s3_key           = aws_s3_object.glue_job_failure_notification_lambda.key
  source_code_hash = data.archive_file.glue_job_failure_notification_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      ADMIN_TAG = "${local.short_identifier_prefix}admin"
    }
  }
}

data "aws_iam_policy_document" "glue_failure_notification_lambda_assume_role" {
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

resource "aws_iam_role" "glue_failure_notification_lambda" {
  tags = module.tags.values

  name               = lower("${local.short_identifier_prefix}glue-failure-notification-lambda")
  assume_role_policy = data.aws_iam_policy_document.glue_failure_notification_lambda_assume_role.json
}

data "aws_iam_policy_document" "glue_failure_notification_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }

  statement {
    actions = [
      "glue:GetJob",
      "glue:GetJobRun",
      "glue:GetTags"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "SNS:ListTopics",
      "SNS:ListTagsForResource"
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
      "arn:aws:sns:*:*:glue-failure-notification-*"
    ]
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "glue_failure_notification_lambda" {
  tags = module.tags.values

  name   = lower("${local.short_identifier_prefix}glue-failure-notification-lambda")
  policy = data.aws_iam_policy_document.glue_failure_notification_lambda.json
}

resource "aws_iam_role_policy_attachment" "glue_failure_notification_lambda" {
  role       = aws_iam_role.glue_failure_notification_lambda.name
  policy_arn = aws_iam_policy.glue_failure_notification_lambda.arn
}

resource "aws_cloudwatch_event_rule" "glue_failure_notification_event_rule" {
  tags = module.tags.values

  name          = "${local.short_identifier_prefix}glue-job-fail"
  description   = "Raise event when a glue job fails"
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

resource "aws_cloudwatch_event_target" "glue_job_failure_lambda_trigger" {
  count = local.is_production_environment ? 1 : 0
  rule  = aws_cloudwatch_event_rule.glue_failure_notification_event_rule.name
  arn   = aws_lambda_function.glue_failure_notification_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_failure_notification_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_failure_notification_event_rule.arn
}

resource "aws_sns_topic" "admin_failure_notifications" {
  tags = merge(module.tags.values, { "PlatformDepartment" = "${local.short_identifier_prefix}admin" })

  name              = "glue-failure-notification-${local.short_identifier_prefix}admin"
  kms_master_key_id = aws_kms_key.admin_failure_notifications_kms_key.key_id
}

resource "aws_kms_key" "admin_failure_notifications_kms_key" {
  tags = merge(module.tags.values, { "PlatformDepartment" = "${local.short_identifier_prefix}admin" })

  description             = "${var.project} - ${var.environment} - glue-failure-notification-${local.short_identifier_prefix}admin KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.admin_failure_notifications_kms_key_policy.json
}

data "aws_iam_policy_document" "admin_failure_notifications_kms_key_policy" {

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
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.data_platform.account_id}:root"]
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

resource "aws_sns_topic_subscription" "admin_failure_notifications" {
  endpoint  = local.google_group_admin_display_name
  protocol  = "email"
  topic_arn = aws_sns_topic.admin_failure_notifications.arn
}
