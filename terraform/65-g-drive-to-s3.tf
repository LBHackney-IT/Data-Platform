data "aws_iam_policy_document" "g_drive_to_s3_copier_lambda_assume_role" {
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

resource "aws_iam_role" "g_drive_to_s3_copier_lambda" {
  # tags = var.tags

  name               = lower("${local.identifier_prefix}-s3-to-s3-copier-lambda")
  assume_role_policy = data.aws_iam_policy_document.g_drive_to_s3_copier_lambda_assume_role.json
}

data "aws_iam_policy_document" "g_drive_to_s3_copier_lambda" {
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
      "kms:*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "*"
      # module.rds_export_storage.kms_key_arn,
      # "${module.rds_export_storage.bucket_arn}/*",
      # var.zone_kms_key_arn,
      # var.zone_bucket_arn,
      # "${var.zone_bucket_arn}/*",
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
      "*"
      # var.zone_bucket_arn,
      # "${var.zone_bucket_arn}/*",
      # module.rds_export_storage.bucket_arn,
      # "${module.rds_export_storage.bucket_arn}/*"
    ]
  }

  # dynamic "statement" {
  #   for_each = var.workflow_arn == "" ? [] : [1]
  #
  #   content {
  #     actions = [
  #       "glue:StartWorkflowRun",
  #     ]
  #     effect = "Allow"
  #     resources = [
  #       var.workflow_arn
  #     ]
  #   }
  # }
}

resource "aws_iam_policy" "g_drive_to_s3_copier_lambda" {
  # tags = var.tags

  name   = lower("${local.identifier_prefix}-s3-to-s3-copier-lambda")
  policy = data.aws_iam_policy_document.g_drive_to_s3_copier_lambda.json
}

resource "aws_iam_role_policy_attachment" "g_drive_to_s3_copier_lambda" {

  role       = aws_iam_role.g_drive_to_s3_copier_lambda.name
  policy_arn = aws_iam_policy.g_drive_to_s3_copier_lambda.arn
}

data "archive_file" "g_drive_to_s3_copier_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/g_drive_to_s3"
  output_path = "../lambdas/g_drive_to_s3.zip"
}

resource "aws_s3_bucket_object" "g_drive_to_s3_copier_lambda" {
  # tags = var.tags

  bucket = module.lambda_artefact_storage.bucket_id
  key    = "s3-to-s3-export-copier.zip"
  source = data.archive_file.g_drive_to_s3_copier_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.g_drive_to_s3_copier_lambda.output_md5
  depends_on = [
    data.archive_file.g_drive_to_s3_copier_lambda
  ]
}

resource "aws_lambda_function" "g_drive_to_s3_copier_lambda" {
  # tags = var.tags

  role             = aws_iam_role.g_drive_to_s3_copier_lambda.arn
  handler          = "main.main"
  runtime          = "python3.8"
  function_name    = "${local.identifier_prefix}-g-drive-to-s3-copier"
  s3_bucket        = module.lambda_artefact_storage.bucket_id
  s3_key           = aws_s3_bucket_object.g_drive_to_s3_copier_lambda.key
  source_code_hash = data.archive_file.g_drive_to_s3_copier_lambda.output_base64sha256
  timeout          = 300 # local.lambda_timeout

  environment {
    variables = {
      BUCKET_DESTINATION = "var.zone_bucket_id",
      SERVICE_AREA       = "var.service_area",
      WORKFLOW_NAME      = "var.workflow_name"
    }
  }

  depends_on = [
    aws_s3_bucket_object.g_drive_to_s3_copier_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "g_drive_to_s3_copier_lambda" {

  function_name          = aws_lambda_function.g_drive_to_s3_copier_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.g_drive_to_s3_copier_lambda
  ]
}
