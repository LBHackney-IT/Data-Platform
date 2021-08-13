resource "aws_s3_bucket_object" "json_to_parquet_script" {
  tags = var.tags

  bucket = var.glue_scripts_bucket_id
  key    = "scripts/json_to_parquet.py"
  acl    = "private"
  source = "../scripts/json_to_parquet.py"
  etag   = filemd5("../scripts/json_to_parquet.py")
}

resource "aws_glue_job" "json_to_parquet" {
  tags = var.tags

  name              = "JSON to Parquet - tascomi - ${var.resource_name}"
  number_of_workers = 10
  worker_type       = "G.1X"
  role_arn          = var.glue_role_arn
  command {
    python_version  = "3"
    script_location = "s3://${var.glue_scripts_bucket_id}/${aws_s3_bucket_object.json_to_parquet_script.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--s3_bucket_source" = local.bucket_source
    "--s3_bucket_target" = local.bucket_target
    "--TempDir"          = var.glue_temp_storage_bucket_id
    "--extra-py-files"   = "s3://${var.glue_scripts_bucket_id}/${var.helpers_script_key}"
  }
}

resource "aws_glue_workflow" "workflow" {
  name = "${var.identifier_prefix}-tascomi-${var.resource_name}"
}

resource "aws_glue_crawler" "json_to_parquet" {
  tags = var.tags

  database_name = var.glue_catalog_database_name
  name          = "raw-zone-tascomi-tascomi-${var.resource_name}"
  role          = var.glue_role_arn
  table_prefix  = "tascomi_"

  s3_target {
    path = local.bucket_target
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}

resource "aws_glue_trigger" "json_to_parquet_trigger" {
  name          = "JSON to Parquet Job Glue Trigger - tascomi - ${var.resource_name}"
  type          = "ON_DEMAND"
  enabled       = true
  workflow_name = aws_glue_workflow.workflow.name

  actions {
    job_name = aws_glue_job.json_to_parquet.name
  }
}

resource "aws_glue_trigger" "json_to_parquet_crawler_trigger" {
  tags = var.tags

  name          = "JSON to Parquet Crawler Trigger - tascomi - ${var.resource_name}"
  type          = "CONDITIONAL"
  enabled       = true
  workflow_name = aws_glue_workflow.workflow.name

  predicate {
    conditions {
      state    = "SUCCEEDED"
      job_name = aws_glue_job.json_to_parquet.name
    }
  }

  actions {
    crawler_name = aws_glue_crawler.json_to_parquet.name
  }
}
