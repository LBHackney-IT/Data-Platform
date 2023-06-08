data "aws_ssm_parameter" "role_arn_to_access_housing_tables_etl" {
  name = "/mtfh/${var.environment}/role-arn-to-access-dynamodb-tables"
}

module "export-mtfh-pitr" {
  count                          = !local.is_production_environment ? 1 : 0
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
  count                      = !local.is_production_environment ? 1 : 0
  job_name                   = "${local.short_identifier_prefix}mtfh-landing-json-to-raw}"
  source                     = "../modules/aws-glue-job"
  is_live_environment        = local.is_live_environment
  is_production_environment  = local.is_production_environment
  department                 = module.department_housing_data_source
  helper_module_key          = data.aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  script_name                = "mtfh_json_export_to_raw"
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
  }
  tags         = module.tags.values
  glue_version = "4.0"
}

locals {
  mtfh_export_stm_definition = <<EOF
  {
  "Comment": "A description of my state machine",
  "StartAt": "Get Table ARN",
  "States": {
    "Get Table ARN": {
      "Type": "Task",
      "Next": "Pass",
      "Parameters": {
        "SecretId": "${aws_secretsmanager_secret.mtfh_export_secret[0].name}"
      },
      "Resource": "arn:aws:states:::aws-sdk:secretsmanager:getSecretValue",
      "ResultPath": "$.secretManagerResponse",
      "InputPath": "$.tableName"
    },
    "Pass": {
      "Type": "Pass",
      "Next": "Lambda Invoke",
      "Parameters": {
        "table_name.$": "$.tableName",
        "s3_bucket": "dataplatform-tim-landing-zone",
        "s3_prefix": "mtfh-exports/",
        "secrets.$": "States.StringToJson($.secretManagerResponse.SecretString)"
      }
    },
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
      "Next": "Pass (1)",
      "ResultPath": "$.lambdaResult"
    },
    "Pass (1)": {
      "Type": "Pass",
      "Next": "Choice",
      "Parameters": {
        "lambda_result_payload.$": "States.StringToJson($.lambdaResult.Payload)",
        "status_code.$": "$.lambdaResult.StatusCode",
        "secrets.$": "$.secrets"
      }
    },
    "Choice": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.status_code",
          "NumericEquals": 200,
          "Next": "Wait After Lambda (30s)"
        }
      ],
      "Default": "Fail (Default)"
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
      ],
      "Default": "Fail (Default)"
    },
    "IN_PROGRESS Wait (30s)": {
      "Type": "Wait",
      "Seconds": 30,
      "Next": "DescribeExport"
    },
    "Fail (Default)": {
      "Type": "Fail"
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
      "Next": "Success"
    },
    "Success": {
      "Type": "Succeed"
    }
  }
}
EOF

  mtfh_tables = ["TenureInformation", "Persons", "ContactDetails", "Assets", "Accounts", "EqualityInformation", "HousingRegister", "HousingRepairsOnline", "PatchesAndAreas", "Processes", "Notes"]
}

resource "aws_secretsmanager_secret" "mtfh_export_secret" {
  count = !local.is_production_environment ? 1 : 0
  name  = "${local.short_identifier_prefix}mtfh-step-functions-again"
  tags  = module.tags.values
}

module "mtfh-state-maching" {
  count             = !local.is_production_environment ? 1 : 0
  source            = "../modules/aws-step-functions"
  name              = "mtfh-export"
  identifier_prefix = local.short_identifier_prefix
  definition        = local.mtfh_export_stm_definition
  role_arn          = aws_iam_role.iam_for_sfn.arn
  tags              = module.tags.values
}

resource "aws_iam_role" "iam_for_sfn" {
  name               = "stepFunctionExecutionIAM"
  tags               = module.tags.values
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "policy_invoke_lambda" {
  name   = "stepFunctionMTFHLambdaFunctionInvocationPolicy"
  tags   = module.tags.values
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "InvokeMTFHLambdaFunction",
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction",
                "lambda:InvokeAsync"
            ],
            "Resource": "${module.export-mtfh-pitr[0].lambda_function_arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "policy_invoke_glue" {
  name   = "stepFunctionMTFHGlueJobInvocationPolicy"
  tags   = module.tags.values
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "InvokeMTFHGlueJob",
            "Effect": "Allow",
            "Action": "glue:StartJobRun",
            "Resource": "${module.glue-mtfh-landing-to-raw[0].job_arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "retrievemtfhsecrets" {
  name   = "stepFunctionMTFHSecretsRetrievalPolicy"
  tags   = module.tags.values
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "RetrieveMTFHSecrets",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${aws_secretsmanager_secret.mtfh_export_secret[0].arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "role_can_assume_housing_reporting_role" {
  name   = "${local.short_identifier_prefix}role_can_assume_housing_reporting_role"
  tags   = module.tags.values
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "roleCanAssumeRole",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "${data.aws_ssm_parameter.role_arn_to_access_housing_tables_etl.value}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_invoke_lambda" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.policy_invoke_lambda.arn
}

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_invoke_glue" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.policy_invoke_glue.arn
}

resource "aws_iam_role_policy_attachment" "iam_for_sfn_attach_policy_retrievemtfhsecrets" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.retrievemtfhsecrets.arn
}

resource "aws_iam_role_policy_attachment" "iam_for_lambda_attach_policy_retrievemtfhsecrets" {
  role       = module.export-mtfh-pitr[0].lambda_iam_role
  policy_arn = aws_iam_policy.retrievemtfhsecrets.arn
}

resource "aws_iam_role_policy_attachment" "iam_for_lambda_role_assume_role" {
  role       = module.export-mtfh-pitr[0].lambda_iam_role
  policy_arn = aws_iam_policy.role_can_assume_housing_reporting_role.arn
}

resource "aws_iam_role_policy_attachment" "iam_policy_for_sfn_can_assume_role" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.role_can_assume_housing_reporting_role.arn
}
