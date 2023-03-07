resource "aws_sagemaker_code_repository" "data_platform" {
  code_repository_name = "${local.identifier_prefix}-notebooks"
  tags                 = module.tags.values

  git_config {
    repository_url = "https://github.com/LBHackney-IT/Data-Platform-Notebooks.git"
    branch         = "main"
  }
}

module "sagemaker" {
  source = "../modules/sagemaker/"
  count  = 0

  development_endpoint_role_arn = aws_iam_role.glue_role.arn
  tags                          = module.tags.values
  identifier_prefix             = local.short_identifier_prefix
  python_libs                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key},s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.pydeequ.key}"
  extra_jars                    = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.jars.key}"
  instance_name                 = "admin"
  github_repository             = aws_sagemaker_code_repository.data_platform.code_repository_name
}

# Cloudwatch event target

resource "aws_cloudwatch_event_rule" "shutdown_notebooks" {
  tags = module.tags.values

  name                = "${local.short_identifier_prefix}schedule-shutting-down-notebooks"
  description         = "Runs task to shut down all notebooks instances and glue development endpoints"
  schedule_expression = "cron(30 18,19,23 ? * MON-FRI *)"
}


resource "aws_lambda_permission" "allow_cloudwatch_to_call_shutdown_notebooks_lambda" {
  count         = 0
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.shutdown_notebooks[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.shutdown_notebooks.arn
}

resource "aws_cloudwatch_event_target" "run_shutdown_notebooks_lambda" {
  count     = 0
  target_id = "shutdown-notebooks-lambda"
  arn       = aws_lambda_function.shutdown_notebooks[0].arn

  rule = aws_cloudwatch_event_rule.shutdown_notebooks.name
}

resource "aws_iam_role" "shutdown_notebooks" {
  count              = 0
  tags               = module.tags.values
  name               = "${local.short_identifier_prefix}shutdown-notebooks-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "shutdown_notebooks" {
  count = 0

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
    sid = "CanListAndDeleteDevEndpoints"
    actions = [
      "glue:GetDevEndpoint*",
      "glue:DeleteDevEndpoint*",
      "glue:ListDevEndpoints"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    sid = "CanListAndStopNotebookInstances"
    actions = [
      "sagemaker:ListNotebookInstances",
      "sagemaker:StopNotebookInstance"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "shutdown_notebooks" {
  count = 0
  tags  = module.tags.values

  name   = "${local.short_identifier_prefix}shutdown-notebooks"
  policy = data.aws_iam_policy_document.shutdown_notebooks[0].json
}

resource "aws_iam_role_policy_attachment" "shutdown_notebooks" {
  count      = 0
  role       = aws_iam_role.shutdown_notebooks[0].name
  policy_arn = aws_iam_policy.shutdown_notebooks[0].arn
}

#  Lambda function 
data "archive_file" "shutdown_notebooks" {
  type        = "zip"
  source_dir  = "../../lambdas/shutdown_notebooks"
  output_path = "../../lambdas/shutdown_notebooks.zip"
}

resource "aws_s3_bucket_object" "shutdown_notebooks" {
  bucket      = module.lambda_artefact_storage.bucket_id
  key         = "shutdown_notebooks.zip"
  source      = data.archive_file.shutdown_notebooks.output_path
  acl         = "private"
  source_hash = data.archive_file.shutdown_notebooks.output_md5
}

resource "aws_lambda_function_event_invoke_config" "shutdown_notebooks" {
  count                  = 0
  function_name          = aws_lambda_function.shutdown_notebooks[0].function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"
}

resource "aws_lambda_function" "shutdown_notebooks" {
  count = 0
  tags  = module.tags.values

  role             = aws_iam_role.shutdown_notebooks[0].arn
  handler          = "main.shutdown_notebooks"
  runtime          = "python3.8"
  function_name    = "${local.short_identifier_prefix}shutdown-notebooks"
  s3_bucket        = module.lambda_artefact_storage.bucket_id
  s3_key           = aws_s3_bucket_object.shutdown_notebooks.key
  source_code_hash = data.archive_file.shutdown_notebooks.output_base64sha256
  timeout          = "60"
}
