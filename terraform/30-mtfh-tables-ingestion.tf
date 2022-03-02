resource "aws_s3_bucket_object" "dynamodb_tables_ingest" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/ingest_tables_from_dynamo_db.py"
  acl         = "private"
  source      = "../scripts/jobs/ingest_tables_from_dynamo_db.py"
  source_hash = filemd5("../scripts/jobs/ingest_tables_from_dynamo_db.py")
}

locals {
  number_of_workers_for_mtfh_ingestion = 12
}

data "aws_ssm_parameter" "role_arn_to_access_housing_tables" {
  name = "/mtfh/${var.environment}/role-arn-to-access-dynamodb-tables"
}

module "ingest_mtfh_tables" {
  source        = "../modules/aws-glue-job"
  environment   = var.environment
  tags          = module.tags.values
  glue_role_arn = aws_iam_role.glue_role.arn

  job_name                       = "${local.short_identifier_prefix}Ingest MTFH tables"
  job_description                = "Ingest a snapshot of the tenures table from the Housing Dynamo DB instance"
  script_s3_object_key           = aws_s3_bucket_object.dynamodb_tables_ingest.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  number_of_workers_for_glue_job = local.number_of_workers_for_mtfh_ingestion
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  job_parameters = {
    "--table_names"       = "TenureInformation", # This is a comma delimited list of Dynamo DB table names to be imported
    "--role_arn"          = data.aws_ssm_parameter.role_arn_to_access_housing_tables.value
    "--s3_target"         = "s3://${module.landing_zone.bucket_id}/mtfh/"
    "--number_of_workers" = local.number_of_workers_for_mtfh_ingestion
  }

  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_catalog_database.name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/mtfh/"
    table_prefix       = "mtfh_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}
