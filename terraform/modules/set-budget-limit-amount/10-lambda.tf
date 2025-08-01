data "aws_iam_policy_document" "set_budget_limit_amount_lambda_assume_role" {
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

resource "aws_iam_role" "set_budget_limit_amount_lambda" {
  tags               = var.tags
  name               = lower("${var.identifier_prefix}set-budget-limit-${var.lambda_name}")
  assume_role_policy = data.aws_iam_policy_document.set_budget_limit_amount_lambda_assume_role.json
}

data "aws_iam_policy_document" "set_budget_limit_amount_lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ce:GetCostAndUsage",
      "budgets:ModifyBudget"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "set_budget_limit_amount_lambda" {
  tags = var.tags

  name   = lower("${var.identifier_prefix}set-budget-limit-amount-lambda")
  policy = data.aws_iam_policy_document.set_budget_limit_amount_lambda.json
}

resource "aws_iam_role_policy_attachment" "set_budget_limit_amount_lambda" {

  role       = aws_iam_role.set_budget_limit_amount_lambda.name
  policy_arn = aws_iam_policy.set_budget_limit_amount_lambda.arn
}

data "archive_file" "set_budget_limit_amount_lambda" {
  type        = "zip"
  source_dir  = "../../lambdas/set_budget_limit_amount"
  output_path = "../../lambdas/set_budget_limit_amount.zip"
}

resource "aws_s3_object" "set_budget_limit_amount_lambda" {
  bucket      = var.lambda_artefact_storage_bucket
  key         = "set_budget_limit_amount.zip"
  source      = data.archive_file.set_budget_limit_amount_lambda.output_path
  acl         = "private"
  source_hash = data.archive_file.set_budget_limit_amount_lambda.output_md5
  depends_on = [
    data.archive_file.set_budget_limit_amount_lambda
  ]
}

resource "aws_lambda_function" "set_budget_limit_amount_lambda" {
  tags = var.tags

  role             = aws_iam_role.set_budget_limit_amount_lambda.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  function_name    = lower("${var.identifier_prefix}set-budget-limit-${var.lambda_name}")
  s3_bucket        = var.lambda_artefact_storage_bucket
  s3_key           = aws_s3_object.set_budget_limit_amount_lambda.key
  source_code_hash = data.archive_file.set_budget_limit_amount_lambda.output_base64sha256
  timeout          = local.lambda_timeout

  environment {
    variables = {
      AccountId = var.account_id
    }
  }
}

resource "aws_lambda_function_event_invoke_config" "set_budget_limit_amount_lambda" {

  function_name          = aws_lambda_function.set_budget_limit_amount_lambda.function_name
  maximum_retry_attempts = 0
  qualifier              = "$LATEST"
}

resource "aws_cloudwatch_event_rule" "run_lambda_to_update_budget_once_a_month" {
  name                = "run_lambda_to_update_budget_once_a_month"
  description         = "triggers the budget update lambda once per month"
  schedule_expression = "cron(0 0 1 * ? *)"
  state               = "DISABLED"
}

resource "aws_cloudwatch_event_target" "run_lambda_to_update_budget_once_a_month" {
  rule      = aws_cloudwatch_event_rule.run_lambda_to_update_budget_once_a_month.name
  target_id = "run_lambda_to_update_budget_once_a_month"
  arn       = aws_lambda_function.set_budget_limit_amount_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_set_budget_limit_amount" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.set_budget_limit_amount_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_lambda_to_update_budget_once_a_month.arn
}
