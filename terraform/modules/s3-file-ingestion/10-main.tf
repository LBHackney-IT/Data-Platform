locals {
  file_ingestions = yamldecode(file("${path.module}/../../../csv_ingestion/${var.config_file}"))
}

module "csv_landing_to_raw_glue_job" {
  count                     = length(local.file_ingestions)
  source                    = "../aws-glue-job"
  is_live_environment       = var.is_live_environment
  is_production_environment = var.is_production_environment

  department                 = var.department
  job_name                   = "csv landing to raw - ${var.department.identifier} - ${local.file_ingestions[count.index].table_name}"
  helper_module_key          = var.helper_module_key
  pydeequ_zip_key            = var.pydeequ_zip_key
  glue_role_arn              = var.glue_role_arn
  script_s3_object_key       = var.spreadsheet_import_script_key
  spark_ui_output_storage_id = var.spark_ui_output_storage_id
  extra_jars                 = ["s3://${var.department.glue_scripts_bucket.bucket_id}/${var.jars_key}"]
  #workflow_name              = aws_glue_workflow.workflow.name

  job_parameters = {
    "--s3_bucket_source"    = "s3://${var.landing_zone_bucket_id}/${var.department.identifier}/${local.file_ingestions[count.index].table_name}/"
    "--s3_bucket_target"    = "s3://${var.raw_zone_bucket_id}/${var.department.identifier}/${local.file_ingestions[count.index].output_path}/${local.file_ingestions[count.index].table_name}"
    "--header_row_number"   = var.header_row_number
    "--job_bookmark_option" = local.job_bookmark_option
  }
}

resource "aws_cloudwatch_event_rule" "s3_event_rule" {
  name = "s3 file ingestion - ${local.file_ingestions[count.index].table_name}"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["s3.amazonaws.com"],
      "eventName" : ["PutObject", "CompleteMultipartUpload"],
      "requestParameters" : {
        "bucketName" : [var.landing_zone_bucket_id]
      }
    }
  })
}

module "filter_and_trigger_lambda" {
  source                         = "../modules/aws-lambda"
  description                    = "Lambda function to filter s3 upload events and trigger Glue jobs"
  lambda_name                    = "${var.identifier_prefix}${var.department.identifier}-s3-ingestion-filter-and-trigger"
  handler                        = "lambda_function.lambda_handler"
  lambda_artefact_storage_bucket = var.lambda_artefact_storage_bucket
  s3_key                         = var.lambda_s3_key
  lamdba_source_dir              = "${path.module}/../../../lambdas/s3-ingestion-filter-and-trigger"
}
