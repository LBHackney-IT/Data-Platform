//Lambda IAM policies
data "aws_iam_policy_document" "parking_liberator_data_upload_lambda_assume_role" {
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

resource "aws_iam_role" "parking_liberator_data_upload_lambda" {
  tags = module.tags.values

  name               = lower("${local.identifier_prefix}-liberator-data-upload-lambda")
  assume_role_policy = data.aws_iam_policy_document.parking_liberator_data_upload_lambda_assume_role.json
}

data "aws_iam_policy_document" "parking_liberator_data_upload_lambda" {
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
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      "${module.landing_zone.bucket_arn}/parking/*"
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    effect = "Allow"
    resources = [
      aws_iam_role.parking_liberator_data_upload_lambda.arn
    ]
  }

  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = [
      module.landing_zone.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "parking_liberator_data_upload_lambda" {
  tags = module.tags.values

  name   = lower("${local.identifier_prefix}-parking-liberator-data-file-upload-lambda")
  policy = data.aws_iam_policy_document.parking_liberator_data_upload_lambda.json
}

resource "aws_iam_role_policy_attachment" "parking_liberator_data_upload_lambda" {
  role       = aws_iam_role.parking_liberator_data_upload_lambda.name
  policy_arn = aws_iam_policy.parking_liberator_data_upload_lambda.arn
}

// Lambda definition
resource "aws_s3_bucket" "parking_lambda_artefact_storage" {
  tags     = module.tags.values

  bucket        = lower("${local.identifier_prefix}-parking-lambda-artefact-storage")
  acl           = "private"
  force_destroy = true
}

data "archive_file" "parking_liberator_data_upload_lambda" {
  type        = "zip"
  source_dir  = "../lambdas/parking_liberator_sftp_to_s3"
  output_path = "../lambdas/parking_liberator_sftp_to_s3.zip"
}

resource "aws_s3_bucket_object" "parking_liberator_data_upload_lambda" {
  tags = module.tags.values

  bucket = aws_s3_bucket.parking_lambda_artefact_storage.id
  key    = "parking_liberator_data_upload_lambda.zip"
  source = data.archive_file.parking_liberator_data_upload_lambda.output_path
  acl    = "private"
  etag   = data.archive_file.parking_liberator_data_upload_lambda.output_md5
  depends_on = [
    data.archive_file.parking_liberator_data_upload_lambda
  ]
}

data "aws_ssm_parameter" "liberator_data_sftp_server_host" {
  name = "/liberator-data/sftp-server-host"
}

data "aws_ssm_parameter" "liberator_data_sftp_server_username" {
  name = "/liberator-data/sftp-server-username"
}

data "aws_ssm_parameter" "liberator_data_sftp_server_password" {
  name = "/liberator-data/sftp-server-password"
}

resource "aws_lambda_function" "parking_liberator_data_upload_lambda" {
  tags = module.tags.values

  role             = aws_iam_role.parking_liberator_data_upload_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs14.x"
  function_name    = "${local.identifier_prefix}_parking_liberator_data_upload"
  s3_bucket        = aws_s3_bucket.parking_lambda_artefact_storage.id
  s3_key           = aws_s3_bucket_object.parking_liberator_data_upload_lambda.key
  source_code_hash = data.archive_file.parking_liberator_data_upload_lambda.output_base64sha256
  timeout          = 900

  environment {
    variables = {
      SFTP_HOST=data.aws_ssm_parameter.liberator_data_sftp_server_host.value
      SFTP_USERNAME=data.aws_ssm_parameter.liberator_data_sftp_server_username.value
      SFTP_PASSWORD=data.aws_ssm_parameter.liberator_data_sftp_server_password.value
      S3_BUCKET=module.landing_zone.bucket_id
    }
  }
}

// Schedule lambda to run daily
resource "aws_cloudwatch_event_rule" "every_day_at_six" {
    name = "every-day-at-six"
    description = "Runs every day at 6am"
    schedule_expression = "cron(0 06 * * ? *)"
}

resource "aws_cloudwatch_event_target" "run_liberator_uploader_every_day" {
    rule = aws_cloudwatch_event_rule.every_day_at_six.name
    target_id = "parking_liberator_data_upload_lambda"
    arn = aws_lambda_function.parking_liberator_data_upload_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_parking_liberator_data_upload_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.parking_liberator_data_upload_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.every_day_at_six.arn
}

