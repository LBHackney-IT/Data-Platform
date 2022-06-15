data "aws_iam_policy_document" "copy_from_s3_to_s3_lambda_assume_role" {
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

resource "aws_iam_role" "copy_from_s3_to_s3" {
  tags = var.tags

  name               = lower("${var.identifier_prefix}-copy-from-s3-to-s3")
  assume_role_policy = data.aws_iam_policy_document.copy_from_s3_to_s3_lambda_assume_role.json
}

data "aws_iam_policy_document" "copy_from_s3_to_s3_lambda" {
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
      "${var.origin_bucket.bucket_arn}/*",
      var.origin_bucket.kms_key_arn,
      "${var.target_bucket.bucket_arn}/*",
      var.target_bucket.kms_key_arn
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
      var.origin_bucket.bucket_arn,
      "${var.origin_bucket.bucket_arn}/*",
      var.target_bucket.bucket_arn,
      "${var.target_bucket.bucket_arn}/*"
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

  #  dynamic "statement" {
  #    for_each = var.workflow_arn == "" ? [] : [1]
  #
  #    content {
  #      actions = [
  #        "glue:StartWorkflowRun",
  #      ]
  #      effect    = "Allow"
  #      resources = [
  #        var.workflow_arn
  #      ]
  #    }
  #  }
}

resource "aws_iam_policy" "copy_from_s3_to_s3_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}-copy-from-s3-to-s3-lambda")
  policy = data.aws_iam_policy_document.copy_from_s3_to_s3_lambda.json
}

resource "aws_iam_role_policy_attachment" "copy_from_s3_to_s3_lambda" {

  role       = aws_iam_role.copy_from_s3_to_s3.name
  policy_arn = aws_iam_policy.copy_from_s3_to_s3_lambda.arn
}

data "archive_file" "copy_from_s3_to_s3_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/copy-from-s3-to-s3"
  output_path = "../lambdas/copy-from-s3-to-s3.zip"
}

resource "aws_s3_object" "copy_from_s3_to_s3_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "copy-from-s3-to-s3.zip"
  source      = data.archive_file.copy_from_s3_to_s3_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.copy_from_s3_to_s3_lambda.output_md5
  depends_on = [
    data.archive_file.copy_from_s3_to_s3_lambda
  ]
}

resource "aws_lambda_function" "copy_from_s3_to_s3_lambda" {
  tags = var.tags

  role             = aws_iam_role.copy_from_s3_to_s3.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${var.identifier_prefix}-copy-from-s3-to-s3"
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_object.copy_from_s3_to_s3_lambda.key
  source_code_hash = data.archive_file.copy_from_s3_to_s3_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      ORIGIN_BUCKET_ID = var.origin_bucket.bucket_id
      ORIGIN_PATH      = var.origin_path
      TARGET_BUCKET_ID = var.target_bucket
      TARGET_PATH      = var.target_path
    }
  }

  depends_on = [
    aws_s3_object.copy_from_s3_to_s3_lambda,
  ]
}

resource "aws_lambda_function_event_invoke_config" "copy_from_s3_to_s3_lambda" {

  function_name          = aws_lambda_function.copy_from_s3_to_s3_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"

  depends_on = [
    aws_lambda_function.copy_from_s3_to_s3_lambda
  ]
}
