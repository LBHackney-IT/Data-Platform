data "aws_iam_policy_document" "housing_landing_zone_access" {
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
<<<<<<< HEAD
      module.landing_zone_data_source.bucket_arn,
      "${module.landing_zone_data_source.bucket_arn}/housing/*",
=======
      module.landing_zone_data_source.bucket_id,
      "${module.landing_zone_data_source.bucket_id}/housing/*",
>>>>>>> main
    ]
  }
}

resource "aws_iam_policy" "housing_landing_zone_access" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "housing_landing_zone_access"
  policy = data.aws_iam_policy_document.housing_landing_zone_access.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "housing_gov_notify_lambda_execution" {
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

resource "aws_iam_policy" "housing_gov_notify_lambda_execution" {
  count  = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name   = "housing_gov_notify_lambda_execution"
  policy = data.aws_iam_policy_document.housing_gov_notify_lambda_execution.json
}

resource "aws_iam_role" "housing_gov_notify_ingestion" {
  count              = local.is_live_environment && !local.is_production_environment ? 1 : 0
  name               = "housing_gov_notify_ingestion_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "housing_gov_notify_ingestion" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.housing_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.housing_landing_zone_access[0].arn
}

resource "aws_iam_role_policy_attachment" "housing_gov_notify_lambda_invoke" {
  count      = local.is_live_environment && !local.is_production_environment ? 1 : 0
  role       = aws_iam_role.housing_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.housing_gov_notify_lambda_execution[0].arn
}