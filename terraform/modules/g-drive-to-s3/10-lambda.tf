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
  tags               = var.tags
  name               = lower("${var.identifier_prefix}from-g-drive-${var.lambda_name}")
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
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.identifier_prefix}/${var.department_identifier}/sheets-credential*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.secrets_manager_kms_key.arn
    ]
  }

  statement {
    actions = [
      "kms:*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      var.zone_kms_key_arn,
      var.zone_bucket_arn,
      "${var.zone_bucket_arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = var.workflow_arns == "" ? [] : [1]

    content {
      actions = [
        "glue:StartWorkflowRun",
      ]
      effect    = "Allow"
      resources = var.workflow_arns
    }
  }
}

resource "aws_iam_policy" "g_drive_to_s3_copier_lambda" {
  tags = var.tags

  name_prefix = lower("${var.identifier_prefix}-g-drive-to-s3-copier-lambda")
  policy      = data.aws_iam_policy_document.g_drive_to_s3_copier_lambda.json
}

resource "aws_iam_role_policy_attachment" "g_drive_to_s3_copier_lambda" {
  role       = aws_iam_role.g_drive_to_s3_copier_lambda.name
  policy_arn = aws_iam_policy.g_drive_to_s3_copier_lambda.arn
}


data "archive_file" "lambda" {
  type        = "zip"
  source_dir  =  "../../lambdas/g_drive_to_s3"
  output_path = "../../lambdas/g_drive_to_s3.zip"
  depends_on  = [null_resource.run_install_requirements]
}

resource "null_resource" "run_install_requirements" {
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/g_drive_to_s3/*") : filesha1("${path.module}/${f}")]))
  }

#   provisioner "local-exec" {
#     interpreter = ["bash", "-c"]
#     command     = "make install-requirements"
#     working_dir = "${path.module}/../../../lambdas/g_drive_to_s3/"
#   }
}

resource "aws_s3_object" "g_drive_to_s3_copier_lambda" {
  bucket = var.lambda_artefact_storage_bucket
  key    = "g_drive_to_s3.zip"
  source = data.archive_file.lambda.output_path
  acl    = "private"
  metadata = {
    last_updated = data.archive_file.lambda.output_base64sha256
  }
  depends_on = [data.archive_file.lambda]
}

resource "aws_lambda_function" "g_drive_to_s3_copier_lambda" {
  tags = var.tags

  role             = aws_iam_role.g_drive_to_s3_copier_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  function_name    = lower("${var.identifier_prefix}g-drive-${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_object.g_drive_to_s3_copier_lambda.key
  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.current.account_id}:layer:google-apis-layer:1",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.current.account_id}:layer:urllib3-1-26-18-layer:1"
    ]
  timeout          = local.lambda_timeout
  memory_size      = local.lambda_memory_size

  environment {
    variables = {
      FILE_ID                                       = var.file_id
      BUCKET_ID                                     = var.zone_bucket_id
      FILE_NAME                                     = "${var.service_area}/${var.output_folder_name}/${var.file_name}"
      WORKFLOW_NAMES                                = join("/", var.workflow_names)
      GOOGLE_SERVICE_ACCOUNT_CREDENTIALS_SECRET_ARN = var.google_service_account_credentials_secret
    }
  }

  depends_on = [
    aws_s3_object.g_drive_to_s3_copier_lambda,
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

resource "aws_cloudwatch_event_rule" "ingestion_schedule" {
  name_prefix         = "g-drive-to-s3-copier-schedule"
  description         = "Ingestion Schedule"
  schedule_expression = var.ingestion_schedule
  is_enabled          = var.ingestion_schedule_enabled ? true : false
}

resource "aws_cloudwatch_event_target" "run_lambda" {
  rule      = aws_cloudwatch_event_rule.ingestion_schedule.name
  target_id = "g_drive_to_s3_copier_lambda"
  arn       = aws_lambda_function.g_drive_to_s3_copier_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_g_drive_to_s3_copier" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.g_drive_to_s3_copier_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ingestion_schedule.arn
}
