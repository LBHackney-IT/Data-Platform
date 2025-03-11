data "aws_iam_policy_document" "s3_to_s3_copier_lambda_assume_role" {
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

resource "aws_iam_role" "s3_to_s3_copier_lambda" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-s3-to-s3-copier-lambda")
  assume_role_policy = data.aws_iam_policy_document.s3_to_s3_copier_lambda_assume_role.json
}

data "aws_iam_policy_document" "s3_to_s3_copier_lambda" {
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
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl"
    ]
    effect = "Allow"
    resources = [
      aws_sqs_queue.s3_to_s3_copier.arn
    ]
  }

  statement {
    actions = [
      "kms:*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      var.rds_export_storage_bucket_arn,
      "${var.rds_export_storage_bucket_arn}/*",
      var.rds_export_storage_kms_key_arn,
      var.zone_kms_key_arn,
      var.zone_bucket_arn,
      "${var.zone_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:CopyObject*",
      "s3:ListBucketVersions",
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      var.zone_bucket_arn,
      "${var.zone_bucket_arn}/*",
      var.rds_export_storage_bucket_arn,
      "${var.rds_export_storage_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "rds:DescribeExportTasks",
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  dynamic "statement" {
    for_each = var.workflow_arn == "" ? [] : [1]

    content {
      actions = [
        "glue:StartWorkflowRun",
      ]
      effect = "Allow"
      resources = [
        var.workflow_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.backdated_workflow_arn == "" ? [] : [1]

    content {
      actions = [
        "glue:StartWorkflowRun",
        "glue:UpdateWorkflow",
      ]
      effect = "Allow"
      resources = [
        var.backdated_workflow_arn
      ]
    }
  }

  statement {
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    effect = "Allow"
    resources = [
      aws_kms_key.s3_to_s3_copier_kms_key.arn
    ]
  }
}

resource "aws_iam_policy" "s3_to_s3_copier_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-s3-to-s3-copier-lambda")
  policy = data.aws_iam_policy_document.s3_to_s3_copier_lambda.json
}

resource "aws_iam_role_policy_attachment" "s3_to_s3_copier_lambda" {

  role       = aws_iam_role.s3_to_s3_copier_lambda.name
  policy_arn = aws_iam_policy.s3_to_s3_copier_lambda.arn
}

data "archive_file" "s3_to_s3_copier_lambda" {
  type        = "zip"
  source_dir  = "../../lambdas/s3-to-s3-export-copier"
  output_path = "../../lambdas/s3-to-s3-export-copier.zip"
}

resource "aws_s3_object" "s3_to_s3_copier_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "s3-to-s3-export-copier.zip"
  source      = data.archive_file.s3_to_s3_copier_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.s3_to_s3_copier_lambda.output_md5
  depends_on = [
    data.archive_file.s3_to_s3_copier_lambda
  ]
  metadata = {
    last_updated = data.archive_file.s3_to_s3_copier_lambda.output_base64sha256
  }
}

resource "aws_lambda_function" "s3_to_s3_copier_lambda" {
  tags = var.tags

  role             = aws_iam_role.s3_to_s3_copier_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${var.identifier_prefix}-s3-to-s3-copier"
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_object.s3_to_s3_copier_lambda.key
  source_code_hash = data.archive_file.s3_to_s3_copier_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      BUCKET_DESTINATION      = var.zone_bucket_id,
      SERVICE_AREA            = var.service_area
      WORKFLOW_NAME           = var.workflow_name
      BACKDATED_WORKFLOW_NAME = var.backdated_workflow_name
    }
  }

  depends_on = [
    aws_s3_object.s3_to_s3_copier_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "s3_to_s3_copier_lambda" {

  function_name          = aws_lambda_function.s3_to_s3_copier_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.s3_to_s3_copier_lambda
  ]
}
