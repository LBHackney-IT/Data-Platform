locals {
  script_name     = var.script_name == null ? "scripts/${var.job_name}.py" : var.script_name
  script_location = "s3://${var.glue_scripts_bucket_id}/${local.script_name}"
}

resource "aws_glue_job" "job" {
  tags = var.department.tags

  name              = var.job_name
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.department.glue_role_arn
  command {
    python_version  = "3"
    script_location = local.script_location
  }

  glue_version = "2.0"

  default_arguments = var.job_parameters
}

resource "aws_glue_trigger" "job_trigger" {
  tags = var.department.tags

  name          = "${var.job_name}-job-trigger"
  type          = (var.triggered_by_crawler != null || var.triggered_by_job != null) ? "CONDITIONAL" : (var.schedule == null ? "ON_DEMAND" : "CONDITIONAL")
  workflow_name = var.workflow_name
  schedule      = var.schedule


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

