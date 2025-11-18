# Lambda function to automatically create/delete Glue Catalog tables
# Workflow: S3 CSV upload/delete → SQS → Lambda → Glue Catalog table create/delete (retry once on failure → DLQ)

data "aws_iam_policy_document" "csv_to_glue_catalog_lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "csv_to_glue_catalog_lambda_execution" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetTables",
      "glue:GetPartitions",
      "glue:DeletePartition",
    ]
    # Currently only scoped to parking
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:database/parking_user_uploads_db",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:table/parking_user_uploads_db/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${module.user_uploads_data_source.bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.user_uploads_data_source.bucket_arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [
      module.user_uploads_data_source.kms_key_arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      aws_sqs_queue.csv_to_glue_catalog_events.arn,
    ]
  }

}

resource "aws_iam_role" "csv_to_glue_catalog_lambda" {
  name               = "${local.short_identifier_prefix}csv-to-glue-catalog-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.csv_to_glue_catalog_lambda_assume_role.json
  tags               = module.tags.values
}

resource "aws_iam_policy" "csv_to_glue_catalog_lambda_execution" {
  name   = "${local.short_identifier_prefix}csv-to-glue-catalog-lambda-execution"
  policy = data.aws_iam_policy_document.csv_to_glue_catalog_lambda_execution.json
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "csv_to_glue_catalog_lambda_execution" {
  role       = aws_iam_role.csv_to_glue_catalog_lambda.name
  policy_arn = aws_iam_policy.csv_to_glue_catalog_lambda_execution.arn
}

module "csv_to_glue_catalog_lambda" {
  source                         = "../modules/aws-lambda"
  lambda_name                    = "csv-to-glue-catalog"
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "csv_to_glue_catalog.zip"
  lambda_source_dir              = "../../lambdas/csv_to_glue_catalog"
  lambda_output_path             = "../../lambdas/csv_to_glue_catalog.zip"
  identifier_prefix              = local.short_identifier_prefix
  lambda_role_arn                = aws_iam_role.csv_to_glue_catalog_lambda.arn
  lambda_timeout                 = 300 # timeout early (5 minutes)
  lambda_memory_size             = 1024
  layers = [
    "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:layer:AWSSDKPandas-Python311:20"
  ]
  description = "Automatically creates/deletes Glue Catalog tables when CSV files are uploaded/deleted in user_uploads bucket"
  environment_variables = {
    GLUE_DATABASE_NAME = "parking_user_uploads_db"
  }
  tags = module.tags.values
}


resource "aws_sqs_queue" "csv_to_glue_catalog_events_dlq" {
  name                      = "${local.short_identifier_prefix}csv-to-glue-catalog-events-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = module.tags.values
}

resource "aws_sqs_queue" "csv_to_glue_catalog_events" {
  name                       = "${local.short_identifier_prefix}csv-to-glue-catalog-events"
  visibility_timeout_seconds = 900
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.csv_to_glue_catalog_events_dlq.arn
    maxReceiveCount     = 2 # 2 attempts before sending to DLQ
  })

  tags = module.tags.values
}

resource "aws_sqs_queue_policy" "csv_to_glue_catalog_events" {
  queue_url = aws_sqs_queue.csv_to_glue_catalog_events.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.csv_to_glue_catalog_events.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = module.user_uploads_data_source.bucket_arn
          }
        }
      }
    ]
  })
}


resource "aws_s3_bucket_notification" "user_uploads_csv_notification" {
  bucket = module.user_uploads_data_source.bucket_id

  queue {
    queue_arn     = aws_sqs_queue.csv_to_glue_catalog_events.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = "parking/" # Currently only scoped to parking
    filter_suffix = ".csv"
  }

  depends_on = [aws_sqs_queue_policy.csv_to_glue_catalog_events]
}


resource "aws_lambda_event_source_mapping" "csv_to_glue_catalog_sqs_trigger" {
  event_source_arn = aws_sqs_queue.csv_to_glue_catalog_events.arn
  function_name    = module.csv_to_glue_catalog_lambda.lambda_function_arn
  batch_size       = 10
  enabled          = true

  scaling_config {
    maximum_concurrency = 2
  }

  function_response_types = ["ReportBatchItemFailures"]
}

resource "aws_cloudwatch_log_group" "csv_to_glue_catalog_lambda_logs" {
  name              = "/aws/lambda/${module.csv_to_glue_catalog_lambda.lambda_name}"
  retention_in_days = 14
  tags              = module.tags.values
}
