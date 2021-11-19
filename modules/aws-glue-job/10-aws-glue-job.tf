locals {
  glue_role_arn  = var.glue_role_arn == null ? var.department.glue_role_arn : var.glue_role_arn
  s3_object_tags = { for k, v in var.department.tags : k => v if k != "PlatformDepartment" }
  extra_jars     = join(",", concat(var.extra_jars, ["s3://${var.department.glue_scripts_bucket.bucket_id}/jars/deequ-1.0.3.jar"]))
}

resource "aws_s3_bucket_object" "job_script" {
  count = var.script_s3_object_key == null ? 1 : 0
  tags  = local.s3_object_tags

  bucket = var.department.glue_scripts_bucket.bucket_id
  key    = "scripts/${var.department.identifier}/${var.script_name}.py"
  acl    = "private"
  source = "../scripts/${var.department.identifier_snake_case}/${var.script_name}.py"
  etag   = filemd5("../scripts/${var.department.identifier_snake_case}/${var.script_name}.py")
}

locals {
  object_key      = var.script_s3_object_key == null ? aws_s3_bucket_object.job_script[0].key : var.script_s3_object_key
  script_location = "s3://${var.department.glue_scripts_bucket.bucket_id}/${local.object_key}"
}

resource "aws_glue_job" "job" {
  tags = var.department.tags

  name              = var.job_name
  number_of_workers = var.number_of_workers_for_glue_job
  worker_type       = var.glue_job_worker_type
  role_arn          = local.glue_role_arn
  command {
    python_version  = "3"
    script_location = local.script_location
  }

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs_of_glue_job
  }

  glue_version = "2.0"

  default_arguments = merge(var.job_parameters,
    {
      "--TempDir"                          = "s3://${var.department.glue_temp_bucket.bucket_id}/${var.department.identifier}/"
      "--extra-py-files"                   = "s3://${var.department.glue_scripts_bucket.bucket_id}/${var.helper_module_key},s3://${var.department.glue_scripts_bucket.bucket_id}/${var.pydeequ_zip_key}"
      "--extra-jars"                       = local.extra_jars
      "--enable-continuous-cloudwatch-log" = "true"
  })
}

locals {
  is_conditional = var.triggered_by_crawler != null || var.triggered_by_job != null
  is_scheduled   = var.schedule != null

  trigger_type = local.is_conditional ? "CONDITIONAL" : (local.is_scheduled ? "SCHEDULED" : "ON_DEMAND")

}

resource "aws_glue_trigger" "job_trigger" {
  tags = var.department.tags

  name          = "${local.job_name_identifier}-job-trigger"
  type          = local.trigger_type
  workflow_name = var.workflow_name
  schedule      = var.schedule
  enabled       = var.trigger_enabled


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

