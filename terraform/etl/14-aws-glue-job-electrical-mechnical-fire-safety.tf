module "communal_lighting" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_communal_lighting"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["communal-lighting"]
  dataset_name                 = "communal-lighting"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "force"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "door_entry" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_door_entry_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["door-entry"]
  dataset_name                 = "door-entry"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "allow"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "dpa" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_dpa"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["dpa"]
  dataset_name                 = "dpa"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "forbid"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "electrical_supplies" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_electrical_supplies_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["electrical-supplies"]
  dataset_name                 = "electrical-supplies"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "allow"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "fire_alarmaov" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_fire_alarmaov_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["fire-alarmaov"]
  dataset_name                 = "fire-alarmaov"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "allow"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "lift_breakdown_el" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_lift_breakdown_ela_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["lift-breakdown---ela"]
  dataset_name                 = "lift-breakdown-ela"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "force"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "lightning_protection" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_lightning_protection_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["lightning-protection"]
  dataset_name                 = "lightning-protection"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "force"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "reactive_rewires" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_reactive_rewires_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["reactive-rewires"]
  dataset_name                 = "reactive-rewires"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "forbid"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "electric_heating" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_electric_heating_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["electric-heating"]
  dataset_name                 = "electric-heating"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "forbid"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}

module "emergency_lighting_servicing" {
  count = local.is_live_environment ? 0 : 0

  source                    = "../modules/electrical-mechnical-fire-safety-cleaning-job"
  is_live_environment       = local.is_live_environment
  is_production_environment = local.is_production_environment

  short_identifier_prefix      = local.short_identifier_prefix
  identifier_prefix            = local.identifier_prefix
  department                   = module.department_housing_repairs_data_source
  script_name                  = "elec_mech_fire_emergency_lighting_servicing_cleaning"
  glue_scripts_bucket_id       = module.glue_scripts_data_source.bucket_id
  glue_role_arn                = data.aws_iam_role.glue_role.arn
  glue_crawler_excluded_blobs  = local.glue_crawler_excluded_blobs
  glue_temp_storage_bucket_url = module.glue_temp_storage_data_source.bucket_url
  refined_zone_bucket_id       = module.refined_zone_data_source.bucket_id
  helper_module_key            = data.aws_s3_object.helpers.key
  pydeequ_zip_key              = data.aws_s3_object.pydeequ.key
  deequ_jar_file_path          = "s3://${module.glue_scripts_data_source.bucket_id}/${aws_s3_object.deeque_jar.key}"
  worksheet_resource           = module.repairs_fire_alarm_aov[0].worksheet_resources["emergency-lighting-servicing"]
  dataset_name                 = "emergency-lighting-servicing"
  address_cleaning_script_key  = aws_s3_object.address_cleaning.key
  address_matching_script_key  = aws_s3_object.levenshtein_address_matching.key
  addresses_api_data_catalog   = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
  trusted_zone_bucket_id       = module.trusted_zone_data_source.bucket_id
  match_to_property_shell      = "force"
  spark_ui_output_storage_id   = module.spark_ui_output_storage_data_source.bucket_id
}




