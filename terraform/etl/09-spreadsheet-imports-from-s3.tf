locals {
  configs = {
    parking = {
      paths = [
        "parking/g-drive/"
      ]
      data_source = module.department_parking_data_source
    },
    housing = {
      paths = [
        "housing/g-drive/"
      ]
      data_source = module.department_housing_data_source
    }
  }

  config_list = [
    for department, config in local.configs : {
      department  = department
      paths       = config.paths
      data_source = config.data_source
    }
  ]

  path_topic_mapping = merge([
    for department, config in local.configs :
    { for path in config.paths : path => aws_sns_topic.sns_topic[path].arn }
  ]...)

  glue_job_name = { for key in keys(local.configs) : key => "${key}-s3-file-upload-landing-to-raw" }

  sns_to_glue_job_lambda_name = { for key in keys(local.configs) : key => "${key}-s3-file-upload-sns-trigger-glue-job" }
}

module "s3_event_to_sns_lambda" {
  source                         = "../modules/aws-lambda"
  lambda_name                    = "s3-event-to-sns"
  handler                        = "main.handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "map-s3-event-to-sns-topic.zip"
  lambda_source_dir              = "${path.module}/../../lambdas/map_s3_event_to_sns_topic"
  runtime                        = "python3.10"
  environment_variables = {
    "PARAMATER_NAME" = aws_ssm_parameter.s3_event_to_sns_topic_mapping.name
  }
}

data "aws_iam_policy_document" "s3_event_to_sns_lambda" {
  statement {
    actions   = ["ssm:GetParameter"]
    effect    = "Allow"
    resources = [aws_ssm_parameter.s3_event_to_sns_topic_mapping.arn]
  }
  statement {
    actions   = ["sns:Publish"]
    effect    = "Allow"
    resources = values(local.path_topic_mapping)
  }
}

resource "aws_iam_policy" "s3_event_to_sns_lambda" {
  name   = "s3-event-to-sns-lambda"
  policy = data.aws_iam_policy_document.s3_event_to_sns_lambda.json
}

resource "aws_iam_role_policy_attachment" "s3_event_to_sns_lambda" {
  role       = module.s3_event_to_sns_lambda.lambda_iam_role_arn
  policy_arn = aws_iam_policy.s3_event_to_sns_lambda.arn
}

resource "aws_ssm_parameter" "s3_event_to_sns_topic_mapping" {
  name  = "department_s3_event_to_sns_topic_mapping"
  type  = "String"
  value = jsonencode(local.path_topic_mapping)
}

resource "aws_sns_topic" "sns_topic" {
  for_each = toset(keys(local.configs))
  name     = "${each.value}-s3-landing-file-upload"
}

module "s3_file_updload_landing_to_raw_glue_job" {
  count                           = length(local.configs)
  source                          = "../modules/aws-glue-job"
  is_live_environment             = local.is_live_environment
  is_production_environment       = local.is_production_environment
  job_name                        = local.glue_job_name[count.index]
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
  department                      = local.config_list[count.index].data_source
  script_s3_object_key            = aws_s3_object.spreadsheet_import_script.key
  max_concurrent_runs_of_glue_job = 10
  tags                            = module.tags.values
  job_parameters = {
    "--s3_bucket_source"  = ""
    "--s3_bucket_target"  = ""
    "--header_row_number" = 0
    "--worksheet_name"    = ""
  }
}

module "sns_topic_to_trigger_glue_job_lambda" {
  count                          = length(local.configs)
  source                         = "../modules/aws-lambda"
  lambda_name                    = local.sns_to_glue_job_lambda_name[count.index]
  handler                        = "main.handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "sns-topic-to-trigger-glue-job.zip"
  lambda_source_dir              = "${path.module}/../../lambdas/start_s3_file_ingestion_glue_job_from_sns_topic"
  runtime                        = "python3.10"
  environment_variables = {
    "GLUE_JOB_NAME" = local.glue_job_name[count.index]
  }
}

data "aws_iam_policy_document" "sns_topic_to_trigger_glue_job_lambda" {
  count = length(local.configs)
  statement {
    actions   = ["glue:StartJobRun"]
    effect    = "Allow"
    resources = [module.s3_file_updload_landing_to_raw_glue_job[count.index].job_arn]
  }
}

resource "aws_iam_policy" "sns_topic_to_trigger_glue_job_lambda" {
  count  = length(local.configs)
  name   = "sns-topic-to-trigger-glue-job-lambda"
  policy = data.aws_iam_policy_document.sns_topic_to_trigger_glue_job_lambda[count.index].json
}

resource "aws_iam_role_policy_attachment" "sns_topic_to_trigger_glue_job_lambda" {
  count      = length(local.configs)
  role       = module.sns_topic_to_trigger_glue_job_lambda[count.index].lambda_iam_role_arn
  policy_arn = aws_iam_policy.sns_topic_to_trigger_glue_job_lambda[count.index].arn
}
