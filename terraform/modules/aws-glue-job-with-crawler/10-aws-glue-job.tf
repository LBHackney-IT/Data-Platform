resource "aws_glue_job" "job" {

  tags = var.tags

  name              = var.job_name
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = var.job_script_location
  }

  glue_version = "2.0"

  default_arguments = var.job_arguments
}

resource "aws_glue_trigger" "job_trigger" {
  tags = var.tags

  name          = "${var.name_prefix}-job-trigger"
  type          = "CONDITIONAL"
  workflow_name = var.workflow_name


  dynamic "predicate" {
    for_each = var.crawler_to_trigger == null ? [] : [1]

    content {
      conditions {
        crawler_name = var.crawler_to_trigger
        crawl_state  = "SUCCEEDED"
      }
    }
  }

  dynamic "predicate" {
    for_each = var.job_to_trigger == null ? [] : [1]

    content {
      conditions {
        job_name = var.job_to_trigger
        state    = "SUCCEEDED"
      }
    }
  }

  actions {
    job_name = aws_glue_job.job.name
  }
}

