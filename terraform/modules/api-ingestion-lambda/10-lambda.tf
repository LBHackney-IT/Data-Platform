data "aws_iam_policy_document" "lambda_assume_role" {
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

locals {
  command = var.runtime_language == "python3.8" ? "make install-requirements" : (var.runtime_language == "nodejs14.x" ? "npm install" : 0)
  # This ensures that this data resource will not be evaluated until
  # after the null_resource has been created.
  lambda_exporter_id = null_resource.run_install_requirements.id

  # This value gives us something to implicitly depend on
  # in the archive_file below.
  source_dir         = "../../lambdas/${local.lambda_name_underscore}"
}

resource "aws_iam_role" "lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda" {
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
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:${var.api_credentials_secret_name}*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "glue:StartTrigger"
    ]
    resources = [
      "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:trigger/${var.trigger_to_run}"
    ]
  }

  statement {
    actions = [
      "kms:*",
      "s3:*"
    ]
    effect = "Allow"
    resources = [
      var.s3_target_bucket_kms_key_arn,
      var.s3_target_bucket_arn,
      "${var.s3_target_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_policy" "lambda" {
  tags = var.tags

  name_prefix = lower("${var.identifier_prefix}lambda-${var.lambda_name}")
  policy      = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "lambda" {

  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}


resource "null_resource" "run_install_requirements" {
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "../../../lambdas/${local.lambda_name_underscore}/*") : filesha1("${path.module}/${f}")]))
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = local.command
    working_dir = "${path.module}/../../../lambdas/${local.lambda_name_underscore}/"
  }
}

data "archive_file" "lambda" {
  type             = "zip"
  source_dir       = local.source_dir
  output_path      = "../../lambdas/${local.lambda_name_underscore}.zip"
  depends_on       = [ null_resource.run_install_requirements ]
  output_file_mode = "0666"
}

resource "aws_s3_bucket_object" "lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "${local.lambda_name_underscore}.zip"
  source      = data.archive_file.lambda.output_path
  acl         = "private"
  source_hash = null_resource.run_install_requirements.triggers["dir_sha1"]
  depends_on  = [ data.archive_file.lambda ]
}

resource "aws_lambda_function" "lambda" {
  tags = var.tags

  role             = aws_iam_role.lambda.arn
  handler          = var.lambda_handler
  runtime          = var.runtime_language
  function_name    = lower("${var.identifier_prefix}${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_bucket_object.lambda.key
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  ephemeral_storage {
    size = var.ephemeral_storage
  }
  environment {
    variables = var.lambda_environment_variables
  }
  
  depends_on = [ 
    null_resource.run_install_requirements,
    aws_s3_bucket_object.lambda
  ]
}

resource "aws_lambda_function_event_invoke_config" "lambda" {
  function_name          = aws_lambda_function.lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"
}

resource "aws_cloudwatch_event_rule" "run_lambda" {
  name_prefix         = "${var.lambda_name}-lambda-"
  description         = "Fires every day at "
  schedule_expression = var.lambda_execution_cron_schedule
  is_enabled          = var.is_production_environment || !var.is_live_environment
}

resource "aws_cloudwatch_event_target" "run_lambda" {
  rule      = aws_cloudwatch_event_rule.run_lambda.name
  target_id = "${var.lambda_name}-"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_lambda.arn
}
#