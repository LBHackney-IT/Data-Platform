module "load_locations_vaccine_to_refined_sandbox" {
  source = "../modules/aws-glue-job"

  department        = module.department_sandbox
  job_name          = "${local.short_identifier_prefix}daro_covid_locations_and_vaccinations"
  script_name       = "daro_covid_locations_and_vaccinations"
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  helper_module_key = aws_s3_bucket_object.helpers.key
  job_parameters = {
    "--cleaned_covid_locations_s3_bucket_target" = "${module.refined_zone.bucket_id}/sandbox/daro-covid-locations-vaccinations-cleaned"
    "--source_catalog_database"                  = module.department_sandbox.raw_zone_catalog_database_name
    "--source_catalog_table"                     = "sandbox_daro_covid_locations"
    "--source_catalog_table2"                    = "sandbox_daro_covid_vaccinations"
  }
  crawler_details = {
    database_name      = module.department_sandbox.refined_zone_catalog_database_name
    s3_target_location = "${module.refined_zone.bucket_id}/sandbox/daro-covid-locations-vaccinations-cleaned"
  }
}

module "job_template" {
  source = "../modules/aws-glue-job"

  department        = module.department_sandbox
  job_name          = "${local.short_identifier_prefix}job_template"
  script_name       = "job_script_template"
  pydeequ_zip_key   = aws_s3_bucket_object.pydeequ.key
  helper_module_key = aws_s3_bucket_object.helpers.key
  job_parameters = {
    "--s3_bucket_target" = "${module.refined_zone.bucket_id}/sandbox/some-target-location-in-the-refined-zone"
    "--source_catalog_database"                  = module.department_sandbox.raw_zone_catalog_database_name
    "--source_catalog_table"                     = "some_table_name"
  }

  crawler_details = {
    database_name      = module.department_sandbox.refined_zone_catalog_database_name
    s3_target_location = "s3://${module.refined_zone.bucket_id}/sandbox/some-target-location-in-the-refined-zone"
    configuration = jsonencode({
      Version = 1.0
    })
  }
}