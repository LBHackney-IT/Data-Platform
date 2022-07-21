locals {
  number_of_workers_for_better_conversations_ingestion = 8
}

data "aws_ssm_parameter" "role_arn_to_access_better_conversations_tables" {
  name = "/better-conversations/prod/role-arn-to-access-dynamodb-tables"
}

module "ingest_better_conversations_tables" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment
  environment               = var.environment
  tags                      = module.tags.values
  glue_role_arn             = aws_iam_role.glue_role.arn

  job_name                       = "${local.short_identifier_prefix}Ingest Better Conversations tables"
  job_description                = "Ingest a snapshot of 2 Better Conversations tables from the API Prod Dynamo DB instance"
  script_s3_object_key           = aws_s3_bucket_object.dynamodb_tables_ingest.key
  helper_module_key              = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key                = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage.bucket_id
  number_of_workers_for_glue_job = local.number_of_workers_for_better_conversations_ingestion
  glue_scripts_bucket_id         = module.glue_scripts.bucket_id
  glue_temp_bucket_id            = module.glue_temp_storage.bucket_id
  job_parameters = {
    "--table_names"       = "cf-snapshot-production-conversations,cf-snapshot-production-referrals"
    "--role_arn"          = data.aws_ssm_parameter.role_arn_to_access_better_conversations_tables.value
    "--s3_target"         = "s3://${module.landing_zone.bucket_id}/better-conversations/"
    "--number_of_workers" = local.number_of_workers_for_better_conversations_ingestion
  }

  crawler_details = {
    database_name      = aws_glue_catalog_database.landing_zone_catalog_database.name
    s3_target_location = "s3://${module.landing_zone.bucket_id}/better-conversations/"
    table_prefix       = "better_conversations_"
    configuration = jsonencode({
      Version = 1.0
      Grouping = {
        TableLevelConfiguration = 3
      }
    })
  }
}
