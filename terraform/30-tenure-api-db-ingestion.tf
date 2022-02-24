resource "aws_s3_bucket_object" "dynamo_db_ingest" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/ingest_from_dynamo_db.py"
  acl         = "private"
  source      = "../scripts/jobs/ingest_from_dynamo_db.py"
  source_hash = filemd5("../scripts/jobs/ingest_from_dynamo_db.py")
}

locals {
  number_of_workers_dynamo = 5
  table_name = "hp-test"
  role_arn = "arn:aws:iam::937934410339:role/glue-can-read-dynamo-db-from-dp-dev-account"
}

resource "aws_glue_job" "ingest_tenures" {
  tags = module.tags.values

  name              = "${local.short_identifier_prefix}Tenures Import Job"
  number_of_workers = local.number_of_workers_dynamo
  worker_type       = "Standard"
  role_arn          = aws_iam_role.glue_role.arn
  timeout           = 120

  command {
    python_version  = "3"
    script_location = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.dynamo_db_ingest.key}"
  }

  glue_version = "2.0"

  default_arguments = {
    "--table_name"                       = local.table_name,
    "--role_arn"                         = local.role_arn,
    "--s3_target"                        = "s3://${module.landing_zone.bucket_id}/${local.table_name}/"
    "--TempDir"                          = "s3://${module.glue_temp_storage.bucket_id}/"
    "--extra-py-files"                   = "s3://${module.glue_scripts.bucket_id}/${aws_s3_bucket_object.helpers.key}"
    "--extra-jars"                       = "s3://${module.glue_scripts.bucket_id}/jars/deequ-1.0.3.jar"
    "--enable-continuous-cloudwatch-log" = "true"
    "--number_of_workers"                = local.number_of_workers_dynamo
  }
}

resource "aws_glue_catalog_database" "tenure_landing_zone" {
  name = "${local.short_identifier_prefix}tenures-landing-zone"
}

resource "aws_glue_crawler" "ingestion_database_connection" {
  tags = module.tags.values

  database_name = aws_glue_catalog_database.tenure_landing_zone.name
  name          = "${local.short_identifier_prefix}tenures-landing-zone-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${module.landing_zone.bucket_id}/hp-test/"

    exclusions = local.glue_crawler_excluded_blobs
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}
