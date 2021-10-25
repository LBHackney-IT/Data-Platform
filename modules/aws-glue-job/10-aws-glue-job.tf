locals {
  script_name     = var.script_name == null ? "scripts/${var.job_name}.py" : var.script_name
  script_location = "s3://${var.glue_scripts_bucket_id}/${local.script_name}"
}

resource "aws_glue_job" "job" {
  tags = var.department.tags

  name              = var.job_name
  number_of_workers = var.number_of_workers_for_glue_job
  worker_type       = var.glue_job_worker_type
  role_arn          = var.department.glue_role_arn
  command {
    python_version  = "3"
    script_location = local.script_location
  }

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs_of_glue_job
  }

  glue_version = "2.0"

  default_arguments = var.job_parameters
}

resource "aws_glue_trigger" "job_trigger" {
  tags = var.department.tags

  name          = "${local.job_name_identifier}-job-trigger"
  type          = (var.triggered_by_crawler != null || var.triggered_by_job != null) ? "CONDITIONAL" : (var.schedule == null ? "ON_DEMAND" : "CONDITIONAL")
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

