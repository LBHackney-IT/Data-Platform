data "aws_iam_policy_document" "rds_snapshot_to_s3_lambda_assume_role" {
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

resource "aws_iam_role" "rds_snapshot_to_s3_lambda" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-rds-snapshot-to-s3-lambda")
  assume_role_policy = data.aws_iam_policy_document.rds_snapshot_to_s3_lambda_assume_role.json
}

data "aws_iam_policy_document" "rds_snapshot_to_s3_lambda" {
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
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]
    effect = "Allow"
    resources = [
      aws_sqs_queue.rds_snapshot_to_s3.arn
    ]
  }

  statement {
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]
    effect = "Allow"
    resources = [
      aws_sqs_queue.s3_to_s3_copier.arn
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    effect = "Allow"
    resources = [
      aws_iam_role.rds_snapshot_export_service.arn
    ]
  }

  statement {
    actions = [
      "rds:DescribeDBSnapshots",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "rds:StartExportTask",
      "rds:DescribeExportTasks"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = [
      var.zone_kms_key_arn,
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
      aws_kms_key.rds_snapshot_to_s3_kms_key.arn
    ]
  }
}

resource "aws_iam_policy" "rds_snapshot_to_s3_lambda" {

  tags = var.tags

  name   = lower("${var.identifier_prefix}-rds-snapshot-to-s3-lambda")
  policy = data.aws_iam_policy_document.rds_snapshot_to_s3_lambda.json
}

resource "aws_iam_role_policy_attachment" "rds_snapshot_to_s3_lambda" {

  role       = aws_iam_role.rds_snapshot_to_s3_lambda.name
  policy_arn = aws_iam_policy.rds_snapshot_to_s3_lambda.arn
}

data "archive_file" "rds_snapshot_to_s3_lambda" {
  type        = "zip"
  source_dir  = "../../lambdas/rds-database-snapshot-replicator"
  output_path = "../../lambdas/rds-database-snapshot-replicator.zip"
}

resource "aws_s3_bucket_object" "rds_snapshot_to_s3_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "rds-snapshot-to-s3.zip"
  source      = data.archive_file.rds_snapshot_to_s3_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.rds_snapshot_to_s3_lambda.output_md5
  depends_on = [
    data.archive_file.rds_snapshot_to_s3_lambda
  ]
}

resource "aws_lambda_function" "rds_snapshot_to_s3_lambda" {

  tags = var.tags

  role             = aws_iam_role.rds_snapshot_to_s3_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${var.identifier_prefix}-rds-snapshot-to-s3"
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.rds_snapshot_to_s3_lambda.key
  source_code_hash = data.archive_file.rds_snapshot_to_s3_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      IAM_ROLE_ARN     = aws_iam_role.rds_snapshot_export_service.arn,
      KMS_KEY_ID       = module.rds_export_storage.kms_key_id,
      S3_BUCKET_NAME   = module.rds_export_storage.bucket_id,
      COPIER_QUEUE_ARN = aws_sqs_queue.s3_to_s3_copier.arn
    }
  }

  depends_on = [
    aws_s3_bucket_object.rds_snapshot_to_s3_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "rds_snapshot_to_s3_lambda" {
  function_name          = aws_lambda_function.rds_snapshot_to_s3_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.rds_snapshot_to_s3_lambda
  ]
}
