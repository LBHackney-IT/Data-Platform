locals {
  is_department_job = var.department != null
  scripts_bucket_id = local.is_department_job ? var.department.glue_scripts_bucket.bucket_id : var.glue_scripts_bucket_id
  environment       = local.is_department_job ? var.department.environment : var.environment

  script = var.script_s3_object_key == null ? {
    key    = local.is_department_job ? "scripts/${var.department.identifier}/${var.script_name}.py" : "scripts/${var.script_name}.py"
    source = local.is_department_job ? "../../scripts/jobs/${var.department.identifier_snake_case}/${var.script_name}.py" : "../../scripts/jobs/${var.script_name}.py"
  } : {}
}

data "aws_s3_object" "job_script" {
  count  = var.script_s3_object_key == null ? 1 : 0
  bucket = local.scripts_bucket_id
  key    = local.script.key
}

locals {
  object_key      = var.script_s3_object_key == null ? data.aws_s3_object.job_script[0].key : var.script_s3_object_key
  job_name_prefix = local.environment == "stg" ? "stg " : ""
}

data "aws_glue_job" "job" {
  name = "${local.job_name_prefix}${var.job_name}"
}

locals {
  is_conditional = var.triggered_by_crawler != null || var.triggered_by_job != null
  is_scheduled   = var.schedule != null

  trigger_type = local.is_conditional ? "CONDITIONAL" : (local.is_scheduled ? "SCHEDULED" : "ON_DEMAND")

}

data "aws_glue_trigger" "job_trigger" {
  name = "${local.job_name_identifier}-job-trigger"
}

