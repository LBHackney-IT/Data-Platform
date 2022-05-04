resource "aws_s3_bucket_object" "alloy_aqs_queries" {
  tags   = module.tags.values
  bucket = "s3://dataplatform-stg-glue-scripts/env_services/alloy/aqs_queries" #this is a placeholder / guess at where these should live
}

data "aws_s3_objects" "alloy_aqs_objects" {
  bucket = "alloy_aqs_queries"
}

data "aws_s3_object" "aqs_query_bodies" {
  count  = length(data.aws_s3_objects.alloy_aqs_objects.keys)
  key    = element(data.aws_s3_objects.alloy_aqs_objects.keys, count.index)
  body   = element(data.aws_s3_objects.alloy_aqs_objects.body, count.index)
  bucket = data.aws_s3_objects.alloy_aqs_objects.bucket
}

module "alloy_api_ingestion_raw_env_services" {
  job_description            = "This job queries the Alloy API for data and converts the exported csv to Parquet saved to S3"
  source                     = "../modules/aws-glue-job"
  department                 = module.department_environmental_services
  job_name                   = "${local.short_identifier_prefix}alloy_api_ingestion_env_services"
  helper_module_key          = aws_s3_bucket_object.helpers.key
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
  script_name                = "alloy_api_ingestion"
  schedule                   = "cron(0 23 ? * MON-FRI *)"
  for_each                   = toset(data.aws_s3_object.aqs_query_bodies.body)
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--enable-glue-datacatalog" = "true"
    "--s3_bucket_target"        = module.raw_zone.bucket_id
    "--s3_prefix"               = "env-services/alloy/api-responses/"
    "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
    "--aqs"                     = each.key
    "--database"                = module.department_environmental_services.raw_zone_catalog_database_name
    "--filename"                = "DW Education&Compliance Inspection/DW Education&Compliance Inspection.csv"
    "--resource"                = "dw_education_and_compliance_inspection"
  }
  crawler_details = {
    database_name      = module.department_environmental_services.raw_zone_catalog_database_name
    s3_target_location = "s3://${module.raw_zone.bucket_id}/env/services/alloy/api_response"
    table_prefix       = "alloy_"
  }
}
