data "aws_iam_policy_document" "streetscene_street_systems_landing_zone_access" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DescribeJob",
      "s3:Get*",
      "s3:List*",
      "s3:PutObject",
      "kms:ListAliases",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:RetireGrant"
    ]

    resources = [
      module.landing_zone_data_source.bucket_arn,
      "${module.landing_zone_data_source.bucket_arn}/streetscene/*",
      module.landing_zone_data_source.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "streetscene_street_systems_landing_zone_access" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "streetscene_street_systems_landing_zone_access"
  policy = data.aws_iam_policy_document.streetscene_street_systems_landing_zone_access.json
}
data "aws_iam_policy_document" "streetscene_street_systems_lambda_logs" {
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

resource "aws_iam_policy" "streetscene_street_systems_lambda_logs" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "streetscene_street_systems_lambda_logs"
  policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_logs.json
}

resource "aws_iam_role_policy_attachment" "streetscene_street_systems_lambda_logs" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_lambda_logs[0].arn
}

data "aws_iam_policy_document" "streetscene_street_systems_lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "streetscene_street_systems_lambda_execution" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "streetscene_street_systems_lambda_execution" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "streetscene_street_systems_lambda_execution"
  policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_execution.json
}

resource "aws_iam_role" "streetscene_street_systems_ingestion" {
  count              = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name               = "streetscene_street_systems_ingestion_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "streetscene_street_systems_ingestion" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_landing_zone_access[0].arn
}

resource "aws_iam_role_policy_attachment" "streetscene_lambda_invoke" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_lambda_execution[0].arn
}

data "aws_iam_policy_document" "streetscene_street_systems_lambda_secret_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:secret:/data-and-insight/streets_systems_api_key*"]
  }
}

resource "aws_iam_policy" "streetscene_street_systems_lambda_secret_access" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "streetscene_street_systems_lambda_secret_access"
  policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_secret_access.json
}

resource "aws_iam_role_policy_attachment" "streetscene_street_systems_lambda_secret_access" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_lambda_secret_access[0].arn
}
