locals {
  govnotify_tables_customer_services                = ["notifications", "received_text_messages"]
  create_govnotify_customer_services_resource_count = local.is_live_environment ? 1 : 0
}


data "aws_iam_policy_document" "customer_services_s3_access" {
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
      "${module.landing_zone_data_source.bucket_arn}/customer-services/*",
      module.landing_zone_data_source.kms_key_arn,
      module.raw_zone_data_source.bucket_arn,
      "${module.raw_zone_data_source.bucket_arn}/customer-services/*",
      module.raw_zone_data_source.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "customer_services_s3_access" {
  count  = local.create_govnotify_customer_services_resource_count
  name   = "customer_services_s3_access"
  policy = data.aws_iam_policy_document.customer_services_s3_access.json
}
data "aws_iam_policy_document" "gov_notify_customer_services_lambda_logs" {
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

resource "aws_iam_policy" "gov_notify_customer_services_lambda_logs" {
  count  = local.create_govnotify_customer_services_resource_count
  name   = "gov_notify_customer_services_lambda_logs"
  policy = data.aws_iam_policy_document.gov_notify_customer_services_lambda_logs.json
}

resource "aws_iam_role_policy_attachment" "gov_notify_customer_services_lambda_logs" {
  count      = local.create_govnotify_customer_services_resource_count
  role       = aws_iam_role.customer_services_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.gov_notify_customer_services_lambda_logs[0].arn
}

data "aws_iam_policy_document" "lambda_assume_role_customer_services" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "customer_services_gov_notify_lambda_execution" {
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

resource "aws_iam_policy" "customer_services_gov_notify_lambda_execution" {
  count  = local.create_govnotify_customer_services_resource_count
  name   = "customer_services_gov_notify_lambda_execution"
  policy = data.aws_iam_policy_document.customer_services_gov_notify_lambda_execution.json
}

resource "aws_iam_role" "customer_services_gov_notify_ingestion" {
  count              = local.create_govnotify_customer_services_resource_count
  name               = "customer_services_gov_notify_ingestion_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_customer_services.json
}

resource "aws_iam_role_policy_attachment" "customer_services_gov_notify_ingestion" {
  count      = local.create_govnotify_customer_services_resource_count
  role       = aws_iam_role.customer_services_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.customer_services_s3_access[0].arn
}

resource "aws_iam_role_policy_attachment" "customer_services_gov_notify_lambda_invoke" {
  count      = local.create_govnotify_customer_services_resource_count
  role       = aws_iam_role.customer_services_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.customer_services_gov_notify_lambda_execution[0].arn
}

data "aws_iam_policy_document" "gov_notify_customer_services_lambda_secret_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:secret:customer-services/gov-notify*"
    ]
  }
}

resource "aws_iam_policy" "gov_notify_customer_services_lambda_secret_access" {
  count  = local.create_govnotify_customer_services_resource_count
  name   = "gov_notify_customer_services_lambda_secret_access"
  policy = data.aws_iam_policy_document.gov_notify_customer_services_lambda_secret_access.json
}

resource "aws_iam_role_policy_attachment" "gov_notify_customer_services_lambda_secret_access" {
  count      = local.create_govnotify_customer_services_resource_count
  role       = aws_iam_role.customer_services_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.gov_notify_customer_services_lambda_secret_access[0].arn
}

# Define a IAM Policy Document for Glue StartCrawler Permissions:
data "aws_iam_policy_document" "gov_notify_customer_services_glue_crawler" {
  statement {
    actions   = ["glue:StartCrawler"]
    effect    = "Allow"
    resources = ["*"]
  }
}

# create a New IAM Policy Resource:
resource "aws_iam_policy" "gov_notify_customer_services_glue_crawler" {
  count  = local.create_govnotify_customer_services_resource_count
  name   = "gov_notify_customer_services_glue_crawler_access"
  policy = data.aws_iam_policy_document.gov_notify_customer_services_glue_crawler.json
}

# attach the gov_notify_glue_crawler to the customer_services_gov_notify_ingestion_lambda_role by creating a new aws_iam_role_policy_attachment resource.
resource "aws_iam_role_policy_attachment" "gov_notify_customer_services_glue_crawler" {
  count      = local.create_govnotify_customer_services_resource_count
  role       = aws_iam_role.customer_services_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.gov_notify_customer_services_glue_crawler[0].arn
}

module "gov-notify-ingestion-customer-services" {
  count                          = local.create_govnotify_customer_services_resource_count
  source                         = "../modules/aws-lambda"
  tags                           = module.tags.values
  lambda_name                    = "govnotify_api_ingestion_customer_services"
  lambda_role_arn                = aws_iam_role.customer_services_gov_notify_ingestion[0].arn
  identifier_prefix              = local.short_identifier_prefix
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "govnotify_api_ingestion_customer_services.zip"
  lambda_source_dir              = "../../lambdas/govnotify_api_ingestion_customer_services"
  lambda_output_path             = "../../lambdas/govnotify_api_ingestion_customer_services.zip"
  runtime                        = "python3.9"
  environment_variables = {

    API_SECRET_NAME          = "customer-services/gov-notify_live_api_key"
    TARGET_S3_BUCKET_LANDING = module.landing_zone_data_source.bucket_id
    TARGET_S3_FOLDER         = "customer-services/govnotify/"
    CRAWLER_NAME_LANDING     = "${local.short_identifier_prefix}GovNotify Customer Services Landing Zone"
    TARGET_S3_BUCKET_RAW     = module.raw_zone_data_source.bucket_id
    CRAWLER_NAME_RAW         = "${local.short_identifier_prefix}GovNotify Customer Services Raw Zone"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python39:13",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:notifications-python-client-9-0-0-layer:1",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:urllib3-1-26-18-layer:1"
  ]
}

# Create a CloudWatch Event Rule to trigger the GovNotify Customer Services Lambda function.
resource "aws_cloudwatch_event_rule" "govnotify_customer_services_trigger_event" {
  count               = local.create_govnotify_customer_services_resource_count
  name                = "${local.short_identifier_prefix}govnotify_customer_services_trigger_event"
  description         = "Trigger event for Customer Services GovNotify API ingestion"
  schedule_expression = "cron(0 0 * * ? *)"
  state               = local.is_production_environment ? "ENABLED" : "DISABLED"
  tags                = module.tags.values
}

# Create a Lambda Permission to allow CloudWatch to invoke the GovNotify Customer Services Lambda function.
resource "aws_lambda_permission" "allow_cloudwatch_to_call_govnotify_customer_services" {
  statement_id  = "AllowCloudWatchToInvokeGovNotifyFunction"
  action        = "lambda:InvokeFunction"
  function_name = module.gov-notify-ingestion-customer-services[0].lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.govnotify_customer_services_trigger_event[0].arn
}

# Create a CloudWatch Event Target to trigger the GovNotify Customer Services Lambda function.
resource "aws_cloudwatch_event_target" "govnotify_customer_services_trigger_event_target" {
  count     = local.create_govnotify_customer_services_resource_count
  rule      = aws_cloudwatch_event_rule.govnotify_customer_services_trigger_event[0].name
  target_id = "govnotify-customer-services-trigger-event-target"
  arn       = module.gov-notify-ingestion-customer-services[0].lambda_function_arn
  input     = <<EOF
   {
    "table_names": ${jsonencode(local.govnotify_tables)}
   }
   EOF
  depends_on = [
    module.gov-notify-ingestion-customer-services,
    aws_lambda_permission.allow_cloudwatch_to_call_govnotify_customer_services
  ]
}

resource "aws_glue_crawler" "govnotify_customer_services_landing_zone" {
  for_each = { for idx, source in local.govnotify_tables_customer_services : idx => source }

  database_name = "${local.identifier_prefix}-landing-zone-database"
  name          = "${local.short_identifier_prefix}GovNotify Customer Services Landing Zone ${each.value}"
  role          = data.aws_iam_role.glue_role.arn
  tags          = module.tags.values
  table_prefix  = "customer_services_${each.value}_"

  s3_target {
    path = "s3://${module.landing_zone_data_source.bucket_id}/customer-services/govnotify/${each.value}/"
  }
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_crawler" "govnotify_customer_services_raw_zone" {
  for_each = { for idx, source in local.govnotify_tables_customer_services : idx => source }

  database_name = module.department_customer_services_data_source.raw_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}GovNotify Customer Services Raw Zone ${each.value}"
  role          = data.aws_iam_role.glue_role.arn
  tags          = module.tags.values
  table_prefix  = null

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/customer-services/govnotify/${each.value}/"
  }
  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableLevelConfiguration = 4
    }
  })
}
