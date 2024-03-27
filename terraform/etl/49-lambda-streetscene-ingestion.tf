locals {
  create_street_systems_resource_count = local.is_live_environment ? 1 : 0
}

data "aws_iam_policy_document" "streetscene_street_systems_raw_zone_access" {
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
      module.raw_zone_data_source.bucket_arn,
      "${module.raw_zone_data_source.bucket_arn}/streetscene/*",
      module.raw_zone_data_source.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "streetscene_street_systems_raw_zone_access" {
  count  = local.is_live_environment ? 1 : 0
  name   = "streetscene_street_systems_raw_zone_access"
  policy = data.aws_iam_policy_document.streetscene_street_systems_raw_zone_access.json
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
  count  = local.is_live_environment ? 1 : 0
  name   = "streetscene_street_systems_lambda_logs"
  policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_logs.json
}

resource "aws_iam_role_policy_attachment" "streetscene_street_systems_lambda_logs" {
  count      = local.is_live_environment ? 1 : 0
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
  count  = local.is_live_environment ? 1 : 0
  name   = "streetscene_street_systems_lambda_execution"
  policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_execution.json
}

resource "aws_iam_role" "streetscene_street_systems_ingestion" {
  count              = local.is_live_environment ? 1 : 0
  name               = "streetscene_street_systems_ingestion_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "streetscene_street_systems_ingestion" {
  count      = local.is_live_environment ? 1 : 0
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_raw_zone_access[0].arn
}

resource "aws_iam_role_policy_attachment" "streetscene_lambda_invoke" {
  count      = local.is_live_environment ? 1 : 0
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
  count  = local.is_live_environment ? 1 : 0
  name   = "streetscene_street_systems_lambda_secret_access"
  policy = data.aws_iam_policy_document.streetscene_street_systems_lambda_secret_access.json
}

resource "aws_iam_role_policy_attachment" "streetscene_street_systems_lambda_secret_access" {
  count      = local.is_live_environment ? 1 : 0
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_lambda_secret_access[0].arn
}

# Define a IAM Policy Document for Glue StartCrawler Permissions:
data "aws_iam_policy_document" "streetscene_street_systems_glue_crawler" {
  statement {
    actions   = ["glue:StartCrawler"]
    effect    = "Allow"
    resources = ["*"]
  }
}

# create a New IAM Policy Resource:
resource "aws_iam_policy" "streetscene_street_systems_glue_crawler" {
  count  = local.create_street_systems_resource_count
  name   = "streetscene_street_systems_glue_crawler_access"
  policy = data.aws_iam_policy_document.streetscene_street_systems_glue_crawler.json
}

# attach the gov_notify_glue_crawler to the housing_gov_notify_ingestion_lambda_role by creating a new aws_iam_role_policy_attachment resource.
resource "aws_iam_role_policy_attachment" "streetscene_street_systems_glue_crawler" {
  count      = local.create_street_systems_resource_count
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = aws_iam_policy.streetscene_street_systems_glue_crawler[0].arn
}

module "street-systems-api-ingestion" {
  count                          = local.is_live_environment ? 1 : 0
  source                         = "../modules/aws-lambda"
  lambda_name                    = "street-systems-export"
  identifier_prefix              = local.short_identifier_prefix
  tags                           = module.tags.values
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "street-systems-api-ingestion.zip"
  lambda_source_dir              = "../../lambdas/street-systems-api-ingestion"
  lambda_output_path             = "../../lambdas/street-systems-api-ingestion.zip"
  runtime                        = "python3.9"
  lambda_role_arn                = aws_iam_role.streetscene_street_systems_ingestion[0].arn
  environment_variables          = {
    API_SECRET_NAME       = "/data-and-insight/streets_systems_api_key"
    OUTPUT_S3_FOLDER      = module.raw_zone_data_source.bucket_id
    TARGET_S3_BUCKET_NAME = "streetscene/traffic-counters/street-systems"
    API_URL = "https://flask-customer-api.ki8kabg62o4fg.eu-west-2.cs.amazonlightsail.com"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:requests-2-31-0-and-httplib-0-22-0-layer:1",
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python39:12",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:s3fs-2023-12-2-layer:1",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:urllib3-1-26-18-layer:1"
  ]
}
resource "aws_cloudwatch_event_rule" "street_systems_api_trigger_event" {
  count               = local.create_street_systems_resource_count
  name                = "${local.short_identifier_prefix}street_systems_api_trigger_event_target"
  description         = "Trigger event for Street Systems API ingestion"
  schedule_expression = "cron(0 0 * * ? *)"
  is_enabled          = local.is_production_environment ? true : false
  tags                = module.tags.values
}

resource "aws_cloudwatch_event_target" "street_systems_api_trigger_event_target" {
  count     = local.create_street_systems_resource_count
  rule      = aws_cloudwatch_event_rule.street_systems_api_trigger_event[0].name
  target_id = "street_systems_api_trigger_event_target"
  arn       = module.street-systems-api-ingestion[0].lambda_function_arn
}

resource "aws_glue_crawler" "streetscene_street_systems_raw_zone" {
  for_each = { for idx, source in local.govnotify_tables : idx => source }

  database_name = "${local.identifier_prefix}-raw-zone-database"
  name          = "${local.short_identifier_prefix}Streetscene Street Systems Raw Zone ${each.value}"
  role          = data.aws_iam_role.glue_role.arn
  tags          = module.tags.values
  table_prefix  = "${each.value}_"

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/streetscene/traffic-counters/street-systems/${each.value}/"
  }
  configuration = jsonencode({
    Version  = 1.0
    Grouping = {
      TableLevelConfiguration = 6
    }
  })
}


