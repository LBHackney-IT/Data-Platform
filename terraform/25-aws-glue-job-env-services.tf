module "alloy_api_ingestion_raw_env_services" {
    job_description            = "This job queries the Alloy API for DW Education&Compliance Inspection data and converts the exported csv to Parquet saved to S3"
    source                     = "../modules/aws-glue-job"
    department                 = module.department_environmental_services
    job_name                   = "${local.short_identifier_prefix}alloy_api_ingestion_env_services"
    helper_module_key          = aws_s3_bucket_object.helpers.key
    pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
    spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id
    script_name                = "alloy_api_ingestion"
    schedule                   = "cron(0 23 ? * MON-FRI *)"
    job_parameters             = {
      "--job-bookmark-option"     = "job-bookmark-enable"
      "--enable-glue-datacatalog" = "true"
      "--s3_bucket_target"        = module.raw_zone.bucket_id
      "--s3_prefix"               = "env-services/alloy/api-responses/"
      "--secret_name"             = "${local.identifier_prefix}/env-services/alloy-api-key"
      "--aqs"                     = "{\"aqs\": {\"type\":\"Join\",\"properties\":{\"dodiCode\":\"designs_wasteEducationInspection_6032eb1356a338006661f6e4\",\"collectionCode\":[\"Live\"],\"attributes\":[\"attributes_itemsTitle\",\"attributes_itemsSubtitle\",\"attributes_itemsGeometry\",\"attributes_inspectionsInspectionNumber\",\"attributes_tasksStatus\",\"attributes_tasksTeam\",\"attributes_tasksRaisedTime\",\"attributes_tasksStartTime\",\"attributes_tasksCompletionTime\",\"attributes_wasteEducationInspectionServiceOutcome_6032eba956a338006661f6f8\",\"attributes_wasteEducationInspectionResidentAvailable_6034de1cca290e006b10eaa5\",\"attributes_wasteEducationInspectionBarriersToRRW_6034e4f16668f2006c62013b\",\"attributes_wasteEducationInspectionEnforcementOutcome_6036a88b267b37006a951ac8\",\"attributes_wasteEducationInspectionEnforcementIssue_603c11fa306e42000a19ee8e\",\"attributes_tasksDescription\",\"attributes_tasksTeamMember\"],\"joinAttributes\":[\"root.attributes_tasksStatus.attributes_taskStatusesStatus\",\"root.attributes_tasksTeam.attributes_teamsTeamName\",\"root.attributes_wasteEducationInspectionServiceOutcome_6032eba956a338006661f6f8.attributes_serviceOutcomeServiceOutcome_602eaaad3cf282006c40f4f0\",\"root.attributes_wasteEducationInspectionBarriersToRRW_6034e4f16668f2006c62013b.attributes_barriersToRRWBarriersToRRW_6034e1c96668f2006c61f949\",\"root.attributes_wasteEducationInspectionEnforcementOutcome_6036a88b267b37006a951ac8.attributes_enforcementOutcomeEnforcementOutcome_602ea67d3cf282006c40f3f3\",\"root.attributes_wasteEducationInspectionEnforcementIssue_603c11fa306e42000a19ee8e.attributes_enforcementIssueEnforcementIssue_603c0f135b27c7000aed8475\",\"root^attributes_tasksAssignableTasks<designs_wasteContainers>^attributes_wasteContainersAssignableWasteContainers<designs_nlpgPremises>.attributes_nlpgPremisesUprn\",\"root^attributes_tasksAssignableTasks<designs_wasteContainers>^attributes_wasteContainersAssignableWasteContainers<designs_nlpgPremises>.attributes_premisesPostcode\",\"root.attributes_tasksTeamMember.attributes_itemsTitle\"],\"sortInfo\":{\"attributeCode\":\"attributes_inspectionsInspectionNumber\",\"sortOrder\":\"Ascending\"}},\"children\":[]},\"fileName\":\"DW Education&Compliance Inspection.csv\",\"exportHeaderType\":\"Name\"}"
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