module "llpg_raw_to_trusted" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                 = module.department_unrestricted_data_source
  job_name                   = "${local.short_identifier_prefix}llpg_latest_to_trusted"
  glue_version               = "4.0"
  glue_job_worker_type       = "G.1X"
  helper_module_key          = data.aws_s3_object.helpers.key
  pydeequ_zip_key            = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"     = "job-bookmark-enable"
    "--s3_bucket_target"        = "s3://${module.trusted_zone_data_source.bucket_id}/unrestricted/llpg/latest_llpg"
    "--enable-glue-datacatalog" = "true"
    "--source_catalog_database" = "unrestricted-raw-zone"
    "--source_catalog_table"    = "geolive_llpg_llpg_address"

  }
  script_name          = "llpg_latest_to_trusted"
  triggered_by_crawler = aws_glue_crawler.raw_zone_unrestricted_address_api_crawler.name

  crawler_details = {
    database_name      = module.department_unrestricted_data_source.trusted_zone_catalog_database_name
    s3_target_location = "s3://${module.trusted_zone_data_source.bucket_id}/unrestricted/llpg/latest_llpg"
    configuration      = null
    table_prefix       = null
  }

}

# 2 jobs for loading AddressBasePremium into unrestricted raw/refined

# Ward look up resource for AddressBasePremium loader
resource "aws_s3_object" "ons_ward_lookup" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/unrestricted/ons_ward_lookup_may_2023.csv"
  acl         = "private"
  source      = "../../scripts/jobs/unrestricted/ons_ward_lookup_may_2023.csv"
  source_hash = filemd5("../../scripts/jobs/unrestricted/ons_ward_lookup_may_2023.csv")
}

# BLPU classification look up resource for AddressBasePremium loader
resource "aws_s3_object" "blpu_class_lookup" {
  bucket      = module.glue_scripts_data_source.bucket_id
  key         = "scripts/unrestricted/blpu_class_lookup.csv"
  acl         = "private"
  source      = "../../scripts/jobs/unrestricted/blpu_class_lookup.csv"
  source_hash = filemd5("../../scripts/jobs/unrestricted/blpu_class_lookup.csv")
}

# Job pre-processing csv files provided by OS
module "addressbasepremium_load_files" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                     = module.department_unrestricted_data_source
  job_name                       = "${local.short_identifier_prefix}addressbasepremium_load_files"
  glue_version                   = "4.0"
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 4
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option" = "job-bookmark-disable"
    "--raw_bucket"          = module.raw_zone_data_source.bucket_id
    "--raw_prefix"          = "unrestricted/os-addressbase-premium/full-supply/epoch-122/raw/"
    "--processed_data_path" = "s3://${module.raw_zone_data_source.bucket_id}/unrestricted/os-addressbase-premium/full-supply/epoch-122/processed/"
  }
  script_name = "addressbasepremium_load_files"
}

# Job using pre-processed csv files to create one national_address table
module "addressbasepremium_create_address_table" {
  source                    = "../modules/aws-glue-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  department                     = module.department_unrestricted_data_source
  job_name                       = "${local.short_identifier_prefix}addressbasepremium_create_address_table"
  glue_version                   = "4.0"
  glue_job_worker_type           = "G.1X"
  number_of_workers_for_glue_job = 8
  helper_module_key              = data.aws_s3_object.helpers.key
  pydeequ_zip_key                = data.aws_s3_object.pydeequ.key
  spark_ui_output_storage_id     = module.spark_ui_output_storage_data_source.bucket_id
  job_parameters = {
    "--job-bookmark-option"        = "job-bookmark-disable"
    "--blpu_class_lookup_path"     = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.blpu_class_lookup.key}"
    "--ward_lookup_path"           = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.ons_ward_lookup.key}"
    "--processed_source_data_path" = "s3://${module.raw_zone_data_source.bucket_id}/unrestricted/os-addressbase-premium/full-supply/epoch-122/processed/"
    "--target_path"                = "s3://${module.refined_zone_data_source.bucket_id}/unrestricted/national_address"
  }
  script_name = "addressbasepremium_create_address_table"
}
