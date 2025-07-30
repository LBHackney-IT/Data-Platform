locals {
  mtfh_tables                    = ["TenureInformation", "Persons", "ContactDetails", "Assets", "Accounts", "EqualityInformation", "HousingRegister", "HousingRepairsOnline", "PatchesAndAreas", "Processes", "Notes"]
  create_mtfh_sfn_resource_count = 1
}

data "aws_ssm_parameter" "role_arn_to_access_housing_tables_etl" {
  name = "/mtfh/${var.environment}/role-arn-to-access-dynamodb-tables"
}

module "export-mtfh-pitr" {
  count                          = local.create_mtfh_sfn_resource_count
  source                         = "../modules/aws-lambda"
  lambda_name                    = "mtfh-export-lambda"
  lambda_source_dir              = "../../lambdas/mtfh_export_lambda"
  lambda_output_path             = "../../lambdas/mtfh_export_lambda.zip"
  handler                        = "main.lambda_handler"
  identifier_prefix              = local.short_identifier_prefix
  lambda_artefact_storage_bucket = module.lambda_artefact_storage_data_source.bucket_id
  s3_key                         = "mtfh_export_lambda.zip"
  environment_variables = {
    SECRET_NAME = aws_secretsmanager_secret.mtfh_export_secret[0].name
  }
  tags = module.tags.values
}

module "glue-mtfh-landing-to-raw" {
  count                      = local.create_mtfh_sfn_resource_count
  job_name                   = "${local.short_identifier_prefix}mtfh-landing-json-to-raw"
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_housing_data_source
  helper_module_key          = data.aws_s3_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "mtfh_json_export_to_raw"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
  }
  tags                 = module.tags.values
  glue_version         = "4.0"
  glue_job_worker_type = "G.1X"
}

resource "aws_secretsmanager_secret" "mtfh_export_secret" {
  count = local.create_mtfh_sfn_resource_count
  name  = "${local.short_identifier_prefix}mtfh-step-functions-again"
  tags  = module.tags.values
}

module "mtfh-state-machine" {
  count             = local.create_mtfh_sfn_resource_count
  source            = "../modules/aws-step-functions"
  name              = "mtfh-export"
  identifier_prefix = local.short_identifier_prefix
  role_arn          = aws_iam_role.iam_for_sfn[0].arn
  tags              = module.tags.values
  definition        = <<EOF
  {
    "Comment": "A description of my state machine",
    "StartAt": "Ingest MTFH Table",
    "States": {
      "Ingest MTFH Table": {
        "Type": "Map",
        "ItemProcessor": {
          "ProcessorConfig": {
            "Mode": "DISTRIBUTED",
            "ExecutionType": "EXPRESS"
          },
          "StartAt": "Lambda Invoke",
          "States": {
            "Lambda Invoke": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "Parameters": {
                "FunctionName": "${module.export-mtfh-pitr[0].lambda_function_arn}",
                "Payload.$": "$"
              },
              "Retry": [
                {
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException",
                    "Lambda.TooManyRequestsException"
                  ],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 6,
                  "BackoffRate": 2
                }
              ],
              "ResultPath": "$.lambdaResult",
              "Next": "Wait After Lambda (30s)"
            },
            "Wait After Lambda (30s)": {
              "Type": "Wait",
              "Seconds": 30,
              "Next": "DescribeExport"
            },
            "DescribeExport": {
              "Type": "Task",
              "Parameters": {
                "ExportArn.$": "$.lambda_result_payload.ExportDescription.ExportArn"
              },
              "Resource": "arn:aws:states:::aws-sdk:dynamodb:describeExport",
              "Next": "DescribeExport State",
              "Credentials": {
                "RoleArn.$": "$.secrets.role_arn"
              }
            },
            "DescribeExport State": {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.ExportDescription.ExportStatus",
                  "StringEquals": "IN_PROGRESS",
                  "Next": "IN_PROGRESS Wait (30s)"
                },
                {
                  "Variable": "$.ExportDescription.ExportStatus",
                  "StringEquals": "FAILED",
                  "Next": "Fail (DescribeExport)"
                },
                {
                  "Variable": "$.ExportDescription.ExportStatus",
                  "StringEquals": "SUCCEEDED",
                  "Next": "Glue StartJobRun"
                }
              ]
            },
            "IN_PROGRESS Wait (30s)": {
              "Type": "Wait",
              "Seconds": 30,
              "Next": "DescribeExport"
            },
            "Fail (DescribeExport)": {
              "Type": "Fail"
            },
            "Glue StartJobRun": {
              "Type": "Task",
              "Resource": "arn:aws:states:::glue:startJobRun",
              "Parameters": {
                "JobName": "${module.glue-mtfh-landing-to-raw[0].job_name}"
              },
              "End": true
            }
          }
        },
        "InputPath": "$.table_names",
        "Catch": [
          {
            "ErrorEquals": [
              "States.ALL"
            ],
            "ResultPath": "$.error-info",
            "Next": "Success"
          }
        ],
        "Next": "Success"
      },
      "Success": {
        "Type": "Succeed"
      }
    }
  }
  EOF
}

resource "aws_cloudwatch_event_rule" "mtfh_export_trigger_event" {
  count               = local.create_mtfh_sfn_resource_count
  name                = "${local.short_identifier_prefix}mtfh-export-trigger-event"
  description         = "Trigger event for MTFH export"
  schedule_expression = "cron(0 0 * * ? *)"
  state               = local.is_production_environment ? "ENABLED" : "DISABLED"
  tags                = module.tags.values
}

resource "aws_cloudwatch_event_target" "mtfh_export_trigger_event_target" {
  count     = local.create_mtfh_sfn_resource_count
  rule      = aws_cloudwatch_event_rule.mtfh_export_trigger_event[0].name
  target_id = "mtfh-export-trigger-event-target"
  arn       = module.mtfh-state-machine[0].arn
  role_arn  = aws_iam_role.iam_for_sfn[0].arn
  input     = <<EOF
  {
   "table_names": ${jsonencode(local.mtfh_tables)}
  }
  EOF
}

resource "aws_iam_role" "iam_for_sfn" {
  count              = local.create_mtfh_sfn_resource_count
  name               = "stepFunctionExecutionIAM"
  tags               = module.tags.values
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role[0].json
}

data "aws_iam_policy_document" "step_functions_assume_role" {
  count = local.create_mtfh_sfn_resource_count
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "retrievemtfhsecrets" {
  count = local.create_mtfh_sfn_resource_count
  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.mtfh_export_secret[0].arn
    ]
  }
}

data "aws_iam_policy_document" "invoke_mtfh_lambda_policy" {
  count = local.create_mtfh_sfn_resource_count
  statement {
    actions = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
    resources = [
      module.export-mtfh-pitr[0].lambda_function_arn
    ]
  }
}

data "aws_iam_policy_document" "mtfh_invoke_glue" {
  count = local.create_mtfh_sfn_resource_count
  statement {
    actions = ["glue:StartJobRun"]
    resources = [
      module.glue-mtfh-landing-to-raw[0].job_arn
    ]
  }
}

data "aws_iam_policy_document" "can_assume_housing_reporting_role" {
  count = local.create_mtfh_sfn_resource_count
  statement {
    actions = ["sts:AssumeRole"]
    resources = [
      data.aws_ssm_parameter.role_arn_to_access_housing_tables_etl.value
    ]
  }
}

data "aws_iam_policy_document" "mtfh_step_functions_policies" {
  count = local.create_mtfh_sfn_resource_count
  source_policy_documents = [
    data.aws_iam_policy_document.invoke_mtfh_lambda_policy[0].json,
    data.aws_iam_policy_document.mtfh_invoke_glue[0].json,
    data.aws_iam_policy_document.can_assume_housing_reporting_role[0].json
  ]
}

data "aws_iam_policy_document" "mtfh_step_functions_policies_for_lambda" {
  count = local.create_mtfh_sfn_resource_count
  source_policy_documents = [
    data.aws_iam_policy_document.retrievemtfhsecrets[0].json,
    data.aws_iam_policy_document.can_assume_housing_reporting_role[0].json
  ]
}

resource "aws_iam_policy" "mtfh_step_functions_policies" {
  count  = local.create_mtfh_sfn_resource_count
  name   = "mtfh_step_functions_policies"
  policy = data.aws_iam_policy_document.mtfh_step_functions_policies[0].json
}

resource "aws_iam_policy" "mtfh_step_functions_policies_for_lambda" {
  count  = local.create_mtfh_sfn_resource_count
  name   = "mtfh_step_functions_policies_for_lambda"
  policy = data.aws_iam_policy_document.mtfh_step_functions_policies_for_lambda[0].json
}

resource "aws_iam_policy_attachment" "mtfh_step_functions_policies" {
  count      = local.create_mtfh_sfn_resource_count
  name       = "mtfh_step_functions_policies"
  roles      = [aws_iam_role.iam_for_sfn[0].name]
  policy_arn = aws_iam_policy.mtfh_step_functions_policies[0].arn
}

resource "aws_iam_policy_attachment" "mtfh_lambda_policies" {
  count      = local.create_mtfh_sfn_resource_count
  name       = "mtfh_lambda_policies"
  roles      = [module.export-mtfh-pitr[0].lambda_iam_role]
  policy_arn = aws_iam_policy.mtfh_step_functions_policies_for_lambda[0].arn
}
