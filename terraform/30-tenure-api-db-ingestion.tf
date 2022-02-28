resource "aws_s3_bucket_object" "dynamo_db_ingest" {
  bucket      = module.glue_scripts.bucket_id
  key         = "scripts/ingest_from_dynamo_db.py"
  acl         = "private"
  source      = "../scripts/jobs/ingest_from_dynamo_db.py"
  source_hash = filemd5("../scripts/jobs/ingest_from_dynamo_db.py")
}

locals {
  number_of_workers_dynamo = 5
  table_name               = "hp-test"
}

data "aws_ssm_parameter" "role_arn_to_access_housing_tables" {
  name = "/mtfh/${var.environment}/role-arn-to-access-dynamodb-tables"
}

module "ingest_tenures" {
  source        = "../modules/aws-glue-job"
  environment   = var.environment
  tags          = module.tags.values
  glue_role_arn = aws_iam_role.glue_role.arn

  job_name                       = "${local.short_identifier_prefix}Tenures Import"
  job_description                = "Ingest a snapshot of the tenures table from the Housing Dynamo DB instance"
  script_s3_object_key           = aws_s3_bucket_object.dynamo_db_ingest.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  number_of_workers_for_glue_job = local.number_of_workers_dynamo
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  job_parameters = {
    "--table_name"        = local.table_name,
    "--role_arn"          = data.aws_ssm_parameter.role_arn_to_access_housing_tables.value
    "--s3_target"         = "s3://${module.landing_zone.bucket_id}/${local.table_name}/"
    "--number_of_workers" = local.number_of_workers_dynamo
  }

  crawler_details = {
    database_name      = aws_glue_catalog_database.tenure_landing_zone.name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/${local.table_name}/"
  }
}

resource "aws_glue_catalog_database" "tenure_landing_zone" {
  name = "${local.short_identifier_prefix}tenures-landing-zone"
}
