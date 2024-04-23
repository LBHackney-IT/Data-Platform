locals {
  create_street_systems_resource_count = local.is_live_environment ? 1 : 0
  traffic_counters_tables                = ["street-systems"] # more table names can be added here
  lambda_layers = [
  "requests-2-31-0-and-httplib-0-22-0-layer",
  # AWS self-managed Pandas layer (aka awswrangler)
  "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python39:12",
  "s3fs-2023-12-2-layer",
  "urllib3-1-26-18-layer"
  ]
  iam_policy_documents = {
    streetscene_street_systems_raw_zone_access = {
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
      ],
      resources = [
        module.raw_zone_data_source.bucket_arn,
        "${module.raw_zone_data_source.bucket_arn}/streetscene/*",
        module.raw_zone_data_source.kms_key_arn
      ]
    },
    streetscene_street_systems_lambda_logs = {
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ],
      resources = ["*"]
    },
    streetscene_street_systems_lambda_execution = {
      actions = [
        "lambda:InvokeFunction"
      ],
      resources = ["*"]
    },
    streetscene_street_systems_lambda_secret_access = {
      actions = [
        "secretsmanager:GetSecretValue",
      ],
      resources = [
        "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:secret:/data-and-insight/streets_systems_api_key*"
      ]
    },
    streetscene_street_systems_glue_crawler = {
      actions = ["glue:StartCrawler"],
      resources = ["*"]
    }
  }
}

# Create the lambda execution policies
resource "aws_iam_policy" "streetscene_policies" {
  for_each = local.create_street_systems_resource_count > 0 ? local.iam_policy_documents : {}
  name   = each.key
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = each.value.actions
        Resource = each.value.resources
      },
    ]
  })
}

# Assume Role Policy (a must for creating IAM roles)
data "aws_iam_policy_document" "streetscene_lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "streetscene_street_systems_ingestion" {
  count              = local.create_street_systems_resource_count
  name               = "streetscene_street_systems_ingestion_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.streetscene_lambda_assume_role.json
}

# Attach execution policies to the lambda role
resource "aws_iam_role_policy_attachment" "streetscene_policy_attachments" {
  for_each   = aws_iam_policy.streetscene_policies
  role       = aws_iam_role.streetscene_street_systems_ingestion[0].name
  policy_arn = each.value.arn
}

# Lambda Function
module "street_systems_api_ingestion" {
  count                          = local.create_street_systems_resource_count
  source                         = "../modules/aws-lambda"
  lambda_name                    = "street_systems_export"
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
    CRAWLER_NAME     = "${local.short_identifier_prefix}Streetscene Street Systems Raw Zone"
  }
  layers = [
    # No where in the etl directory reference aws-lambda-layers module, so can't use layer ARNs from its output
    # "contains" checks if the string layer contains the substring "arn:aws:". It returns true if the substring is found, and false otherwise
    for layer in local.lambda_layers: 
      contains(layer, "arn:aws:") ? 
        layer : 
        "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:${layer}:1"
  ]
}

# Cloudwatch Event Rule
resource "aws_cloudwatch_event_rule" "street_systems_api_trigger_event" {
  count               = local.create_street_systems_resource_count
  name                = "${local.short_identifier_prefix}street_systems_api_trigger_event_target"
  description         = "Trigger event for Street Systems API ingestion"
  schedule_expression = "cron(0 0 * * ? *)"
  is_enabled          = local.is_production_environment ? true : false
  tags                = module.tags.values
}

# Permission to allow CloudWatch to invoke Lambda function (a must for triggering lambda function)
resource "aws_lambda_permission" "allow_cloudwatch_to_call_street_systems" {
  count         = local.create_street_systems_resource_count
  statement_id  = "AllowCloudWatchToInvokeGovNotifyFunction"
  action        = "lambda:InvokeFunction"
  function_name = module.street_systems_api_ingestion[0].lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.street_systems_api_trigger_event[0].arn
}

# Cloudwatch Event Target to trigger Lambda function
resource "aws_cloudwatch_event_target" "street_systems_api_trigger_event_target" {
  count     = local.create_street_systems_resource_count
  rule      = aws_cloudwatch_event_rule.street_systems_api_trigger_event[0].name
  target_id = "street_systems_api_trigger_event_target"
  arn       = module.street_systems_api_ingestion[0].lambda_function_arn
  input     = <<EOF
  {
  "table_names": ${jsonencode(local.traffic_counters_tables)}
  }
  EOF
  depends_on = [module.street_systems_api_ingestion[0], aws_lambda_permission.allow_cloudwatch_to_call_street_systems[0]]
 }

# Glue Crawler to crawl the raw zone data
resource "aws_glue_crawler" "streetscene_street_systems_raw_zone" {
  for_each = { for idx, source in local.traffic_counters_tables : idx => source }
  database_name = "${local.identifier_prefix}-raw-zone-database"
  name          = "${local.short_identifier_prefix}Streetscene Street Systems Raw Zone" # Must same as the CRAWLER_NAME in lambda
  role          = data.aws_iam_role.glue_role.arn
  tags          = module.tags.values
  table_prefix  = "${each.value}_"

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/streetscene/traffic-counters/${each.value}/"
  }
  configuration = jsonencode({
    Version  = 1.0
    Grouping = {
      TableLevelConfiguration = 6
    }
  })
}


