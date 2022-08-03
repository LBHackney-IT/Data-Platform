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
    resources = concat(
      [
        "${var.origin_bucket.bucket_arn}/*",
        "${var.target_bucket.bucket_arn}/*",
      ],
      var.origin_bucket.kms_key_arn != null ? [var.origin_bucket.kms_key_arn] : [],
      var.target_bucket.kms_key_arn != null ? [var.target_bucket.kms_key_arn] : []
    )
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

resource "null_resource" "lambda_builder" {
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "lambda/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "npm install"
    working_dir = "${path.module}/lambda/"
  }
}

data "null_data_source" "wait_for_lambda_exporter" {
  inputs = {
    # This ensures that this data resource will not be evaluated until
    # after the null_resource has been created.
    lambda_exporter_id = null_resource.lambda_builder.id

    # This value gives us something to implicitly depend on
    # in the archive_file below.
    source_dir = "${path.module}/lambda"
  }
}

data "archive_file" "lambda_source_code" {
  type        = "zip"
  source_dir  = data.null_data_source.wait_for_lambda_exporter.outputs["source_dir"]
  output_path = "${path.module}/copy-from-s3-to-s3.zip"
}

resource "aws_s3_object" "copy_from_s3_to_s3_lambda" {
  bucket      = var.lambda_artefact_storage_bucket.bucket_id
  key         = "copy-from-s3-to-s3.zip"
  source      = data.archive_file.lambda_source_code.output_path
  acl         = "private"
  source_hash = data.archive_file.lambda_source_code.output_md5
  depends_on = [
    data.archive_file.lambda_source_code
  ]
}

resource "aws_lambda_function" "copy_from_s3_to_s3_lambda" {
  tags = var.tags

  role             = aws_iam_role.copy_from_s3_to_s3.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${var.identifier_prefix}-${var.lambda_name}"
  s3_bucket        = var.lambda_artefact_storage_bucket.bucket_id
  s3_key           = aws_s3_object.copy_from_s3_to_s3_lambda.key
  source_code_hash = data.archive_file.lambda_source_code.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      ORIGIN_BUCKET_ID = var.origin_bucket.bucket_id
      ORIGIN_PATH      = var.origin_path
      TARGET_BUCKET_ID = var.target_bucket.bucket_id
      TARGET_PATH      = var.target_path
      ASSUME_ROLE_ARN  = var.assume_role != false ? var.assume_role : null
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
