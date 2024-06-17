module "team_times_ingestion" {
  count                          = !local.is_production_environment ? 1 : 0
  source                         = "../modules/aws-lambda"
  lambda_name                    = "team_times"
  lambda_source_dir              = "../../lambdas/team_times"
  lambda_output_path             = "../../lambdas/team_times.zip"
  handler                        = "main.main"
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "team_times.zip"
  lambda_role_arn                = aws_iam_role.team_times_lambda_execution[0].arn
  environment_variables = {
    API_ENDPOINT    = aws_ssm_parameter.team_times_api_enpoint[0].name,
    SECRET_NAME     = aws_ssm_parameter.team_times_api_key[0].name,
    FREQUENCY       = "D",
    XML_BUCKET_NAME = module.landing_zone_data_source.bucket_id,
    CSV_BUCKET_NAME = module.raw_zone_data_source.bucket_id,
    XML_PREFIX      = "parking/team_times",
    CSV_PREFIX      = "parking/team_times"
  }
  tags = module.tags.values
}

resource "aws_ssm_parameter" "team_times_api_key" {
  count       = !local.is_production_environment ? 1 : 0
  name        = "/parking/team_times_api_key"
  description = "API key for Team Times"
  type        = "SecureString"
  value       = "MANAGED MANUALLY"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

resource "aws_ssm_parameter" "team_times_api_enpoint" {
  count       = !local.is_production_environment ? 1 : 0
  name        = "/parking/team_times_api_endpoint"
  description = "API endpoint for Team Times"
  type        = "String"
  value       = "MANAGED MANUALLY"
  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

data "aws_iam_policy_document" "team_times_lambda_assume_role" {
  count = !local.is_production_environment ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "team_times_lambda_ssm_access" {
  count = !local.is_production_environment ? 1 : 0
  statement {
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.data_platform.account_id}:parameter/parking/team_times*"
    ]
  }
}

data "aws_iam_policy_document" "team_times_lambda_s3_write_access" {
  count = !local.is_production_environment ? 1 : 0
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:List*",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      module.landing_zone_data_source.bucket_arn,
      module.raw_zone_data_source.bucket_arn,
      "${module.landing_zone_data_source.bucket_arn}/parking/team_times*",
      "${module.raw_zone_data_source.bucket_arn}/parking/team_times*"
    ]
  }
  statement {
    actions = [
      "kms:ListAliases",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]
    effect = "Allow"
    resources = [
      module.landing_zone_data_source.kms_key_arn,
      module.raw_zone_data_source.kms_key_arn
    ]
  }
}

data "aws_iam_policy_document" "team_times_lambda_logs" {
  count = !local.is_production_environment ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "team_times_lambda_invoke" {
  count = !local.is_production_environment ? 1 : 0
  statement {
    actions = ["lambda:InvokeFunction"]
    effect  = "Allow"
    resources = [
      module.team_times_ingestion[0].lambda_function_arn
    ]
  }
}

data "aws_iam_policy_document" "team_times_lambda_assignment" {
  count = !local.is_production_environment ? 1 : 0
  source_policy_documents = [
    data.aws_iam_policy_document.team_times_lambda_ssm_access[0].json,
    data.aws_iam_policy_document.team_times_lambda_s3_write_access[0].json,
    data.aws_iam_policy_document.team_times_lambda_logs[0].json,
    data.aws_iam_policy_document.team_times_lambda_invoke[0].json
  ]
}

resource "aws_iam_policy" "team_times_lambda_execution" {
  count  = !local.is_production_environment ? 1 : 0
  name   = "team_times_lambda_execution"
  policy = data.aws_iam_policy_document.team_times_lambda_assignment[0].json
}

resource "aws_iam_role" "team_times_lambda_execution" {
  count              = !local.is_production_environment ? 1 : 0
  name               = "team_times_lambda_execution"
  assume_role_policy = data.aws_iam_policy_document.team_times_lambda_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "team_times_lambda_assignment" {
  count      = !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.team_times_lambda_execution[0].name
  policy_arn = aws_iam_policy.team_times_lambda_execution[0].arn
}
