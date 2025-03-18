locals {
  govnotify_tables_housing_communal_repairs = ["notifications"]
}


data "aws_iam_policy_document" "gov_notify_housing_communal_repairs_lambda_secret_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    effect    = "Allow"
    resources = [
      "arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:secret:housing-lbh-communal-repairs/gov-notify*"
    ]
  }
}

resource "aws_iam_policy" "gov_notify_housing_communal_repairs_lambda_secret_access" {
  count  = local.create_govnotify_resource_count
  name   = "gov_notify_housing_communal_repairs_lambda_secret_access"
  policy = data.aws_iam_policy_document.gov_notify_housing_communal_repairs_lambda_secret_access.json
}

resource "aws_iam_role_policy_attachment" "gov_notify_housing_communal_repairs_lambda_secret_access" {
  count      = local.create_govnotify_resource_count
  role       = aws_iam_role.housing_gov_notify_ingestion[0].name
  policy_arn = aws_iam_policy.gov_notify_housing_communal_repairs_lambda_secret_access[0].arn
}

module "gov-notify-ingestion-housing-communal-repairs" {
  count                          = local.create_govnotify_resource_count
  source                         = "../modules/aws-lambda"
  tags                           = module.tags.values
  lambda_name                    = "govnotify_api_ingestion_housing_lbh_communal_repairs"
  lambda_role_arn                = aws_iam_role.housing_gov_notify_ingestion[0].arn
  identifier_prefix              = local.short_identifier_prefix
  handler                        = "main.lambda_handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "govnotify_api_ingestion_housing_lbh_communal_repairs.zip"
  lambda_source_dir              = "../../lambdas/govnotify_api_ingestion_housing_lbh_communal_repairs"
  lambda_output_path             = "../../lambdas/govnotify_api_ingestion_housing_lbh_communal_repairs.zip"
  runtime                        = "python3.9"
  environment_variables          = {

    API_SECRET_NAME          = "housing-lbh-communal-repairs/gov-notify_live_api_key"
    TARGET_S3_BUCKET_LANDING = module.landing_zone_data_source.bucket_id
    TARGET_S3_FOLDER         = "housing/govnotify/lbh_communal_repairs/"
    CRAWLER_NAME_LANDING     = "${local.short_identifier_prefix}GovNotify Housing LBH Communal Repairs Landing Zone"
    TARGET_S3_BUCKET_RAW     = module.raw_zone_data_source.bucket_id
    CRAWLER_NAME_RAW         = "${local.short_identifier_prefix}GovNotify Housing LBH Communal Repairs Raw Zone"
  }
  layers = [
    "arn:aws:lambda:eu-west-2:336392948345:layer:AWSSDKPandas-Python39:13",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:notifications-python-client-9-0-0-layer:1",
    "arn:aws:lambda:eu-west-2:${data.aws_caller_identity.data_platform.account_id}:layer:urllib3-1-26-18-layer:1"
  ]
}

resource "aws_cloudwatch_event_rule" "govnotify_housing_lbh_communal_repairs_trigger_event" {
  count       = local.create_govnotify_resource_count
  name        = "${local.short_identifier_prefix}govnotify_housing_lbh_communal_repairs_trigger_event"
  description = "Trigger event for Housing LBH Communal Repairs GovNotify API ingestion"
  tags        = module.tags.values
  schedule_expression = "cron(0 0 * * ? *)"
  is_enabled          = local.is_production_environment ? true : false
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_govnotify_housing_lbh_communal_repairs" {
  statement_id  = "AllowCloudWatchToInvokeGovNotifyFunction"
  action        = "lambda:InvokeFunction"
  function_name = module.gov-notify-ingestion-housing-communal-repairs[0].lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.govnotify_housing_lbh_communal_repairs_trigger_event[0].arn
}

resource "aws_cloudwatch_event_target" "govnotify_housing_lbh_communal_repairs_trigger_event_target" {
  count      = local.create_govnotify_resource_count
  rule       = aws_cloudwatch_event_rule.govnotify_housing_lbh_communal_repairs_trigger_event[0].name
  target_id  = "govnotify-housing-communal-repairs-event-target"
  arn        = module.gov-notify-ingestion-housing-communal-repairs[0].lambda_function_arn
  input      = <<EOF
   {
    "table_names": ${jsonencode(local.govnotify_tables_housing_communal_repairs)}
   }
   EOF
  depends_on = [
    module.gov-notify-ingestion-housing-communal-repairs,
    aws_lambda_permission.allow_cloudwatch_to_call_govnotify_housing_lbh_communal_repairs
  ]
}

resource "aws_glue_crawler" "govnotify_housing_lbh_communal_repairs_landing_zone" {
  for_each = {for idx, source in local.govnotify_tables_housing_communal_repairs : idx => source}

  database_name = "${local.identifier_prefix}-landing-zone-database"
  name          = "${local.short_identifier_prefix}GovNotify Housing LBH Communal Repairs Landing Zone ${each.value}"
  role          = data.aws_iam_role.glue_role.arn
  tags          = module.tags.values
  table_prefix  = "housing_lbh_communal_repairs_${each.value}_"

  s3_target {
    path = "s3://${module.landing_zone_data_source.bucket_id}/housing/govnotify/lbh_communal_repairs/${each.value}/"
  }
  configuration = jsonencode({
    Version  = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

resource "aws_glue_crawler" "govnotify_housing_lbh_communal_repairs_raw_zone" {
  for_each = {for idx, source in local.govnotify_tables_housing_communal_repairs : idx => source}

  database_name = module.department_housing_data_source.raw_zone_catalog_database_name
  name          = "${local.short_identifier_prefix}GovNotify Housing LBH Communal Repairs Raw Zone ${each.value}"
  role          = data.aws_iam_role.glue_role.arn
  tags          = module.tags.values
  table_prefix  = "housing_lbh_communal_repairs_"

  s3_target {
    path = "s3://${module.raw_zone_data_source.bucket_id}/housing/govnotify/lbh_communal_repairs/${each.value}/"
  }
  configuration = jsonencode({
    Version  = 1.0
    Grouping = {
      TableLevelConfiguration = 5
    }
  })
}

