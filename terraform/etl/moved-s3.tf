moved {
  from = aws_s3_bucket_object.address_cleaning
  to   = aws_s3_object.address_cleaning
}
moved {
  from = aws_s3_bucket_object.address_matching
  to   = aws_s3_object.address_matching
}
moved {
  from = aws_s3_bucket_object.convertbng
  to   = aws_s3_object.convertbng
}
moved {
  from = aws_s3_bucket_object.copy_manually_uploaded_csv_data_to_raw
  to   = aws_s3_object.copy_manually_uploaded_csv_data_to_raw
}
moved {
  from = aws_s3_bucket_object.copy_tables_landing_to_raw
  to   = aws_s3_object.copy_tables_landing_to_raw
}
moved {
  from = aws_s3_bucket_object.deeque_jar
  to   = aws_s3_object.deeque_jar
}
moved {
  from = aws_s3_bucket_object.get_uprn_from_uhref
  to   = aws_s3_object.get_uprn_from_uhref
}
moved {
  from = aws_s3_bucket_object.glue_job_failure_notification_lambda
  to   = aws_s3_object.glue_job_failure_notification_lambda
}
moved {
  from = aws_s3_bucket_object.google_sheets_import_script
  to   = aws_s3_object.google_sheets_import_script
}
moved {
  from = aws_s3_bucket_object.housing_repairs_dlo_cleaning_script
  to   = aws_s3_object.housing_repairs_dlo_cleaning_script
}
moved {
  from = aws_s3_bucket_object.levenshtein_address_matching
  to   = aws_s3_object.levenshtein_address_matching
}
moved {
  from = aws_s3_bucket_object.spreadsheet_import_script
  to   = aws_s3_object.spreadsheet_import_script
}
moved {
  from = aws_s3_bucket_object.tascomi_column_type_dictionary
  to   = aws_s3_object.tascomi_column_type_dictionary
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[0].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[0].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[1].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[1].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[2].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[2].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[3].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[3].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[4].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[4].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[5].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[5].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[6].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[6].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[7].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[7].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[8].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[8].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[9].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[9].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[10].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[10].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[11].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[11].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[12].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[12].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_api_ingestion_raw_env_services[13].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_api_ingestion_raw_env_services[13].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[0].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[0].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[1].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[1].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[2].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[2].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[3].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[3].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[4].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[4].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[5].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[5].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[6].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[6].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[7].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[7].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[9].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[9].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[10].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[10].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[11].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[11].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[12].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[12].aws_s3_object.job_script[0]
}
moved {
  from = module.alloy_daily_snapshot_env_services[13].aws_s3_bucket_object.job_script[0]
  to   = module.alloy_daily_snapshot_env_services[13].aws_s3_object.job_script[0]
}
moved {
  from = module.communal_lighting[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.communal_lighting[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.covid_vaccinations_arda_sandbox.aws_s3_bucket_object.job_script[0]
  to   = module.covid_vaccinations_arda_sandbox.aws_s3_object.job_script[0]
}
moved {
  from = module.covid_vaccinations_verlander_sandbox.aws_s3_bucket_object.job_script[0]
  to   = module.covid_vaccinations_verlander_sandbox.aws_s3_object.job_script[0]
}
moved {
  from = module.door_entry[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.door_entry[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.dpa[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.dpa[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.electric_heating[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.electric_heating[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.electrical_supplies[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.electrical_supplies[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.emergency_lighting_servicing[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.emergency_lighting_servicing[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.etl_ctax_live_properties.aws_s3_bucket_object.job_script[0]
  to   = module.etl_ctax_live_properties.aws_s3_object.job_script[0]
}
moved {
  from = module.fire_alarmaov[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.fire_alarmaov[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.housing_repairs_alphatrack[0].aws_s3_bucket_object.housing_repairs_repairs_cleaning_script
  to   = module.housing_repairs_alphatrack[0].aws_s3_object.housing_repairs_repairs_cleaning_script
}
moved {
  from = module.housing_repairs_avonline[0].aws_s3_bucket_object.housing_repairs_repairs_cleaning_script
  to   = module.housing_repairs_avonline[0].aws_s3_object.housing_repairs_repairs_cleaning_script
}
moved {
  from = module.housing_repairs_axis[0].aws_s3_bucket_object.housing_repairs_repairs_cleaning_script
  to   = module.housing_repairs_axis[0].aws_s3_object.housing_repairs_repairs_cleaning_script
}
moved {
  from = module.housing_repairs_herts_heritage[0].aws_s3_bucket_object.housing_repairs_repairs_cleaning_script
  to   = module.housing_repairs_herts_heritage[0].aws_s3_object.housing_repairs_repairs_cleaning_script
}
moved {
  from = module.housing_repairs_purdy[0].aws_s3_bucket_object.housing_repairs_repairs_cleaning_script
  to   = module.housing_repairs_purdy[0].aws_s3_object.housing_repairs_repairs_cleaning_script
}
moved {
  from = module.housing_repairs_stannah[0].aws_s3_bucket_object.housing_repairs_repairs_cleaning_script
  to   = module.housing_repairs_stannah[0].aws_s3_object.housing_repairs_repairs_cleaning_script
}
moved {
  from = module.ingest_tascomi_data.aws_s3_bucket_object.job_script[0]
  to   = module.ingest_tascomi_data.aws_s3_object.job_script[0]
}
moved {
  from = module.job_template.aws_s3_bucket_object.job_script[0]
  to   = module.job_template.aws_s3_object.job_script[0]
}
moved {
  from = module.job_template_tim.aws_s3_bucket_object.job_script[0]
  to   = module.job_template_tim.aws_s3_object.job_script[0]
}
moved {
  from = module.liberator_fpns_to_refined.aws_s3_bucket_object.job_script[0]
  to   = module.liberator_fpns_to_refined.aws_s3_object.job_script[0]
}
moved {
  from = module.lift_breakdown_el[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.lift_breakdown_el[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.lightning_protection[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.lightning_protection[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.llpg_raw_to_trusted.aws_s3_bucket_object.job_script[0]
  to   = module.llpg_raw_to_trusted.aws_s3_object.job_script[0]
}
moved {
  from = module.load_covid_data_to_refined_adam.aws_s3_bucket_object.job_script[0]
  to   = module.load_covid_data_to_refined_adam.aws_s3_object.job_script[0]
}
moved {
  from = module.load_covid_data_to_refined_marta.aws_s3_bucket_object.job_script[0]
  to   = module.load_covid_data_to_refined_marta.aws_s3_object.job_script[0]
}
moved {
  from = module.load_locations_vaccine_to_refined_sandbox.aws_s3_bucket_object.job_script[0]
  to   = module.load_locations_vaccine_to_refined_sandbox.aws_s3_object.job_script[0]
}
moved {
  from = module.mtfh_reshape_to_refined.aws_s3_bucket_object.job_script[0]
  to   = module.mtfh_reshape_to_refined.aws_s3_object.job_script[0]
}
moved {
  from = module.noisework_complaints_to_refined.aws_s3_bucket_object.job_script[0]
  to   = module.noisework_complaints_to_refined.aws_s3_object.job_script[0]
}
moved {
  from = module.parking_pcn_report_summary.aws_s3_bucket_object.job_script[0]
  to   = module.parking_pcn_report_summary.aws_s3_object.job_script[0]
}
moved {
  from = module.reactive_rewires[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.reactive_rewires[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.steve_covid_locations_and_vaccinations_sandbox.aws_s3_bucket_object.job_script[0]
  to   = module.steve_covid_locations_and_vaccinations_sandbox.aws_s3_object.job_script[0]
}
moved {
  from = module.stg_job_template_huu_do_sandbox.aws_s3_bucket_object.job_script[0]
  to   = module.stg_job_template_huu_do_sandbox.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_applications_to_trusted.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_applications_to_trusted.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_create_daily_snapshot.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_create_daily_snapshot.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_locations_to_trusted.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_locations_to_trusted.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_officers_teams_to_trusted.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_officers_teams_to_trusted.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_parse_tables_increments.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_parse_tables_increments.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_recast_tables_increments.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_recast_tables_increments.aws_s3_object.job_script[0]
}
moved {
  from = module.tascomi_subsidiary_tables_to_trusted.aws_s3_bucket_object.job_script[0]
  to   = module.tascomi_subsidiary_tables_to_trusted.aws_s3_object.job_script[0]
}
moved {
  from = module.tv_aerials[0].aws_s3_bucket_object.housing_repairs_elec_mech_fire_data_cleaning_script
  to   = module.tv_aerials[0].aws_s3_object.housing_repairs_elec_mech_fire_data_cleaning_script
}
moved {
  from = module.data_and_insight_hb_combined[0].module.import_file_from_g_drive.aws_s3_bucket_object.g_drive_to_s3_copier_lambda
  to   = module.data_and_insight_hb_combined[0].module.import_file_from_g_drive.aws_s3_object.g_drive_to_s3_copier_lambda
}
moved {
  from = module.env_enforcement_cc_tv[0].module.import_file_from_g_drive.aws_s3_bucket_object.g_drive_to_s3_copier_lambda
  to   = module.env_enforcement_cc_tv[0].module.import_file_from_g_drive.aws_s3_object.g_drive_to_s3_copier_lambda
}
moved {
  from = module.env_enforcement_estate_cleaning[0].module.import_file_from_g_drive.aws_s3_bucket_object.g_drive_to_s3_copier_lambda
  to   = module.env_enforcement_estate_cleaning[0].module.import_file_from_g_drive.aws_s3_object.g_drive_to_s3_copier_lambda
}
moved {
  from = module.env_enforcement_fix_my_street_noise[0].module.import_file_from_g_drive.aws_s3_bucket_object.g_drive_to_s3_copier_lambda
  to   = module.env_enforcement_fix_my_street_noise[0].module.import_file_from_g_drive.aws_s3_object.g_drive_to_s3_copier_lambda
}
moved {
  from = module.repairs_fire_alarm_aov[0].module.import_file_from_g_drive.aws_s3_bucket_object.g_drive_to_s3_copier_lambda
  to   = module.repairs_fire_alarm_aov[0].module.import_file_from_g_drive.aws_s3_object.g_drive_to_s3_copier_lambda
}