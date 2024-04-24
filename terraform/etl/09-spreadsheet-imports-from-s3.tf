locals {
  configs = {
    parking = {
      paths = [
        "parking/g-drive/"
      ]
      department_module = module.department_parking_data_source
    },
    housing = {
      paths = [
        "housing/g-drive/"
      ]
      department_module = module.department_housing_data_source
    }
  }

  config_map = {
    for department, config in local.configs : department => {
      department                  = department
      paths                       = config.paths
      department_module           = config.department_module
      glue_job_name               = "${department}-s3-file-upload-landing-to-raw"
      sns_to_glue_job_lambda_name = "${department}-s3-file-upload-sns-trigger-glue-job"
    }
  }

  path_department_pairs = flatten([
    for department, config in local.configs : [
      for path in config.paths : {
        path       = path,
        department = department
      }
    ]
  ])

  path_topic_mapping = {
    for pair in local.path_department_pairs : pair.path => aws_sns_topic.sns_topic[pair.department].arn
  }
}

module "s3_event_to_sns_lambda" {
  source                         = "../modules/aws-lambda"
  lambda_name                    = "s3-event-to-sns"
  handler                        = "main.handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "map-s3-event-to-sns-topic.zip"
  lambda_source_dir              = "../../lambdas/map_s3_event_to_sns_topic"
  lambda_output_path             = "../../lambdas/map_s3_event_to_sns_topic.zip"
  runtime                        = "python3.9"
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
  tags   = module.tags.values
}

resource "aws_iam_role_policy_attachment" "s3_event_to_sns_lambda" {
  role       = module.s3_event_to_sns_lambda.lambda_iam_role_arn
  policy_arn = aws_iam_policy.s3_event_to_sns_lambda.arn
}

resource "aws_ssm_parameter" "s3_event_to_sns_topic_mapping" {
  name  = "department_s3_event_to_sns_topic_mapping"
  type  = "String"
  value = jsonencode(local.path_topic_mapping)
  tags  = module.tags.values
}

resource "aws_sns_topic" "sns_topic" {
  for_each = toset(keys(local.configs))
  name     = "${each.value}-s3-landing-file-upload"
}

module "s3_file_updload_landing_to_raw_glue_job" {
  for_each                        = local.config_map
  source                          = "../modules/aws-glue-job"
  is_live_environment             = local.is_live_environment
  is_production_environment       = local.is_production_environment
  job_name                        = each.value.glue_job_name
  helper_module_key               = data.aws_s3_object.helpers.key
  pydeequ_zip_key                 = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id      = module.spark_ui_output_storage_data_source.bucket_id
  department                      = each.value.department_module
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
  for_each                       = local.config_map
  source                         = "../modules/aws-lambda"
  lambda_name                    = each.value.sns_to_glue_job_lambda_name
  handler                        = "main.handler"
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "sns-topic-to-trigger-glue-job.zip"
  lambda_source_dir              = "../../lambdas/start_s3_file_ingestion_glue_job_from_sns_topic"
  lambda_output_path             = "../../lambdas/start_s3_file_ingestion_glue_job_from_sns_topic.zip"
  runtime                        = "python3.9"
  environment_variables = {
    "GLUE_JOB_NAME" = each.value.glue_job_name
  }
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  for_each  = local.config_map
  topic_arn = aws_sns_topic.sns_topic[each.key].arn
  protocol  = "lambda"
  endpoint  = module.sns_topic_to_trigger_glue_job_lambda[each.key].lambda_arn
}

data "aws_iam_policy_document" "sns_topic_to_trigger_glue_job_lambda" {
  for_each = local.config_map
  statement {
    actions   = ["glue:StartJobRun"]
    effect    = "Allow"
    resources = [each.value.glue_job_name]
  }
}

resource "aws_iam_policy" "sns_topic_to_trigger_glue_job_lambda" {
  for_each = local.config_map
  name     = "sns-topic-to-trigger-glue-job-lambda"
  policy   = data.aws_iam_policy_document.sns_topic_to_trigger_glue_job_lambda[each.key].json
}

resource "aws_iam_role_policy_attachment" "sns_topic_to_trigger_glue_job_lambda" {
  for_each   = local.config_map
  role       = module.sns_topic_to_trigger_glue_job_lambda[each.key].lambda_iam_role_arn
  policy_arn = aws_iam_policy.sns_topic_to_trigger_glue_job_lambda[each.key].arn
}
