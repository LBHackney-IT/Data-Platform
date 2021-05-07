// ==== LAMBDA ====================================================================================================== //
data "aws_iam_policy_document" "rds_snapshot_to_s3_lambda" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "service"
    }
  }
}

resource "aws_iam_role" "rds_snapshot_to_s3_lambda" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = lower("${local.identifier_prefix}-rds-snapshots-lambda")
  assume_role_policy = data.aws_iam_policy_document.rds_snapshot_to_s3_lambda
}

data "aws_iam_policy_document" "rds_snapshot_to_s3_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    effect    = "Allow"
    resources = [aws_sqs_queue.rds_snapshot_to_s3.arn]
  }

  statement {
    actions   = ["iam:PassRole"]
    effect    = "Allow"
    resources = [aws_iam_role.rds_snapshot_export_service.arn]
  }

  statement {
    actions = [
      "rds:DescribeDBSnapshots",
    ]
    effect  = "Allow"
    resources = ["arn:aws:rds:*:*:snapshot:*"]
  }

  statement {
    actions = [
      "rds:StartExportTask"
    ]
    effect  = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rds_snapshot_to_s3_lambda" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-rds-snapshot-to-s3-lambda")
  policy = data.aws_iam_policy_document.rds_snapshot_to_s3_lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  provider = aws.aws_api_account

  role       = aws_iam_role.rds_snapshot_to_s3_lambda.name
  policy_arn = aws_iam_policy.rds_snapshot_to_s3_lambda.arn
}

resource "aws_s3_bucket" "lambda_artefact_storage" {
  provider = aws.aws_api_account
  tags = module.tags.values

  bucket        = lower("${local.identifier_prefix}-lambda-artefact-storage")
  acl           = "private"
  force_destroy = true
}

data "archive_file" "rds_snapshot_to_s3_lambda" {
  type        = "zip"
  source_dir = "../lambdas/rds-database-snapshot-replicator"
  output_path = "../lambdas/rds-database-snapshot-replicator.zip"
}

resource "aws_s3_bucket_object" "rds_snapshot_to_s3_lambda" {
  provider = aws.aws_api_account
  tags = module.tags.values

  bucket = aws_s3_bucket.lambda_artefact_storage.bucket
  key    = "rds_snapshot_to_s3_lambda.zip"
  source = data.archive_file.rds_snapshot_to_s3_lambda.output_path
  acl    = "private"
  etag   = filemd5(data.archive_file.rds_snapshot_to_s3_lambda.output_path)
  depends_on = [
    data.archive_file.rds_snapshot_to_s3_lambda
  ]
}

resource "aws_lambda_function" "rds_snapshot_to_s3_lambda" {
  provider = aws.aws_api_account
  tags = module.tags.values

  role             = aws_iam_role.rds_snapshot_to_s3_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "rds_snapshot_to_s3_lambda"
  s3_bucket        = aws_s3_bucket.lambda_artefact_storage.bucket
  s3_key           = aws_s3_bucket_object.rds_snapshot_to_s3_lambda.key
  source_code_hash = data.archive_file.rds_snapshot_to_s3_lambda.output_base64sha256

  environment {
    variables = {
      IAM_ROLE_ARN   = aws_iam_role.rds_snapshot_export_service.arn,
      KMS_KEY_ID     = module.landing_zone.kms_key_arn,
      S3_BUCKET_NAME = module.landing_zone.bucket_id,
    }
  }

  depends_on = [
    aws_s3_bucket_object.rds_snapshot_to_s3_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "rds_snapshot_to_s3_lambda" {
  provider = aws.aws_api_account

  function_name          = aws_lambda_function.rds_snapshot_to_s3_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.rds_snapshot_to_s3_lambda
  ]
}

data "aws_iam_policy_document" "rds_snapshot_export_service_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["export.rds.amazonaws.com"]
      type = "service"
    }
  }
}

resource "aws_iam_role" "rds_snapshot_export_service" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = "rds_export_process_role"
  assume_role_policy = data.aws_iam_policy_document.rds_snapshot_export_service_assume_role
}

data "aws_iam_policy_document" "rds_snapshot_export_service" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject*",
      "s3:GetObject*",
      "s3:CopyObject*",
      "s3:DeleteObject*"
    ]
    resources = [
      "arn:aws:s3:::data-platform-snapshot-export-test",
      "arn:aws:s3:::data-platform-snapshot-export-test/*"
    ]
  }
}

resource "aws_iam_policy" "rds_snapshot_export_service" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = "rds_export_process_policy"
  description = "A policy that allows the RDS Snapshot Service to write to the Data Platform S3 Landing Zone"
  policy = data.aws_iam_policy_document.rds_snapshot_export_service
}

resource "aws_iam_role_policy_attachment" "rds_snapshot_export_service" {
  provider = aws.aws_api_account

  role = aws_iam_role.rds_snapshot_export_service.name
  policy_arn = aws_iam_policy.rds_snapshot_export_service.arn
}


// ==== SNS TOPIC =================================================================================================== //
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
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sns_cloudwatch_logging" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = lower("${local.identifier_prefix}-sns-cloudwatch-logging")
  policy = data.aws_iam_policy_document.sns_cloudwatch_logging_policy.json
}

data "aws_iam_policy_document" "sns_cloudwatch_logging_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["sns.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "sns_cloudwatch_logging" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = lower("${local.identifier_prefix}-sns-cloudwatch-logging")
  assume_role_policy = data.aws_iam_policy_document.sns_cloudwatch_logging_assume_role.json
}

resource "aws_iam_policy_attachment" "sns_cloudwatch_policy_attachment" {
  provider = aws.aws_api_account

  name = lower("${local.identifier_prefix}-sns-cloudwatch-logging-policy")
  roles = [aws_iam_role.sns_cloudwatch_logging.name]
  policy_arn = aws_iam_policy.sns_cloudwatch_logging.arn
}

resource "aws_sns_topic" "ingestion_topic" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = lower("${local.identifier_prefix}-rds-snapshot-to-s3")
  sqs_success_feedback_role_arn = aws_iam_role.sns_cloudwatch_logging.arn
  sqs_success_feedback_sample_rate = 100
  sqs_failure_feedback_role_arn = aws_iam_role.sns_cloudwatch_logging.arn
}


// ==== SQS TOPIC =================================================================================================== //
resource "aws_sqs_queue" "rds_snapshot_to_s3" {
  provider = aws.aws_api_account
  tags = module.tags.values

  name = lower("${local.identifier_prefix}-rds-snapshot-to-s3")
}

resource "aws_sns_topic_subscription" "ingestion_sqs_target" {
  provider = aws.aws_api_account

  topic_arn = aws_sns_topic.ingestion_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.rds_snapshot_to_s3.arn
}

//resource "aws_lambda_event_source_mapping" "event_source_mapping" {
//  provider = aws.aws_api_account
//
//  event_source_arn = aws_sqs_queue.ingestion_queue.arn
//  enabled          = true
//  function_name    = aws_lambda_function.rds_snapshot_to_s3_lambda.arn
//  batch_size       = 1
//}

//resource "aws_sns_topic_subscription" "lambda" {
//  provider = aws.aws_api_account
//
//  topic_arn = aws_sns_topic.ingestion_topic.arn
//  protocol  = "lambda"
//  endpoint  = aws_lambda_function.rds_snapshot_to_s3_lambda.arn
//}
