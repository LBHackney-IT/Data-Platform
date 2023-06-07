locals {
  is_department_job = var.department != null
  scripts_bucket_id = local.is_department_job ? var.department.glue_scripts_bucket.bucket_id : var.glue_scripts_bucket_id
  tags              = local.is_department_job ? var.department.tags : var.tags
  temp_directory    = local.is_department_job ? "s3://${var.department.glue_temp_bucket.bucket_id}/${var.department.identifier}/" : "s3://${var.glue_temp_bucket_id}/"
  environment       = local.is_department_job ? var.department.environment : var.environment
  glue_role_arn     = var.glue_role_arn == null ? var.department.glue_role_arn : var.glue_role_arn
  extra_jars        = join(",", concat(var.extra_jars, ["s3://${local.scripts_bucket_id}/jars/deequ-1.0.3.jar"]))
  spark_ui_storage  = local.is_department_job ? "s3://${var.spark_ui_output_storage_id}/${var.department.identifier}/${local.job_name_identifier}/" : "s3://${var.spark_ui_output_storage_id}/${local.job_name_identifier}/"

  script = var.script_s3_object_key == null ? {
    key    = local.is_department_job ? "scripts/${var.department.identifier}/${var.script_name}.py" : "scripts/${var.script_name}.py"
    source = local.is_department_job ? "../../scripts/jobs/${var.department.identifier_snake_case}/${var.script_name}.py" : "../../scripts/jobs/${var.script_name}.py"
  } : {}
}

resource "aws_s3_bucket_object" "job_script" {
  count = var.script_s3_object_key == null ? 1 : 0

  bucket      = local.scripts_bucket_id
  key         = local.script.key
  acl         = "private"
  source      = local.script.source
  source_hash = filemd5(local.script.source)
}

locals {
  object_key      = var.script_s3_object_key == null ? aws_s3_bucket_object.job_script[0].key : var.script_s3_object_key
  job_name_prefix = local.environment == "stg" ? "stg " : ""
}

resource "aws_glue_job" "job" {
  tags = local.tags

  name              = "${local.job_name_prefix}${var.job_name}"
  number_of_workers = var.number_of_workers_for_glue_job
  worker_type       = var.glue_job_worker_type
  max_retries       = var.max_retries
  role_arn          = local.glue_role_arn
  timeout           = var.glue_job_timeout
  connections       = var.jdbc_connections
  execution_class   = var.execution_class

  command {
    python_version  = "3"
    script_location = "s3://${local.scripts_bucket_id}/${local.object_key}"
  }

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs_of_glue_job
  }

  glue_version = var.glue_version

  default_arguments = merge(var.job_parameters,
    {
      "--TempDir"                          = local.temp_directory
      "--extra-py-files"                   = "s3://${local.scripts_bucket_id}/${var.helper_module_key},s3://${local.scripts_bucket_id}/${var.pydeequ_zip_key}"
      "--extra-jars"                       = local.extra_jars
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-spark-ui"                  = "true"
      "--spark-event-logs-path"            = local.spark_ui_storage
  })
}

locals {
  is_conditional = var.triggered_by_crawler != null || var.triggered_by_job != null
  is_scheduled   = var.schedule != null

  trigger_type = local.is_conditional ? "CONDITIONAL" : (local.is_scheduled ? "SCHEDULED" : "ON_DEMAND")

}

resource "aws_glue_trigger" "job_trigger" {
  tags = local.tags

  name          = "${local.job_name_identifier}-job-trigger"
  type          = local.trigger_type
  workflow_name = var.workflow_name
  schedule      = var.schedule
  enabled       = var.trigger_enabled && (var.is_production_environment || !var.is_live_environment)


  dynamic "predicate" {
    for_each = var.triggered_by_crawler == null ? [] : [1]

    content {
      conditions {
        crawler_name = var.triggered_by_crawler
        crawl_state  = "SUCCEEDED"
      }
    }
  }

  dynamic "predicate" {
    for_each = var.triggered_by_job == null ? [] : [1]

    content {
      conditions {
        job_name = var.triggered_by_job
        state    = "SUCCEEDED"
      }
    }
  }

  actions {
    job_name = aws_glue_job.job.name
  }
}

