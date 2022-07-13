locals {
  tuomo_data_flow_table_filter_expressions_test_db = {
    person                       = "^testdb.dbo.dm_persons$",
    address                      = "^testdb.dbo.dm_addresses$",
    team                         = "^testdb.dbo.sccv_team$",
    worker                       = "^testdb.dbo.sccv_worker$",
    allocation-combined          = "^testdb.dbo.sccv_allocations_combined$",
    worker-team                  = "^testdb.dbo.sccv_workerteam$",
    uprn-update                  = "^testdb.dbo.sccv_uprn_update$",
    key-contact                  = "^testdb.dbo.dm_key_contacts$",
    warning-note-review          = "^testdb.dbo.sccv_warning_note_review$",
    request-audit                = "^testdb.dbo.sccv_request_audit$",
    telephone-number             = "^testdb.dbo.dm_telephone_numbers$",
    person-last-update           = "^testdb.dbo.dm_person_last_updated$",
    person-other-name            = "^testdb.dbo.sccv_person_other_name$",
    worker-import                = "^testdb.dbo.sccv_worker_import$",
    person-case-status           = "^testdb.dbo.sccv_person_case_status$",
    person-import                = "^testdb.dbo.sccv_persons_import$",
    other-email-address          = "^testdb.dbo.dm_other_email_addresses$",
    personal-relationship-type   = "^testdb.dbo.sccv_personal_relationship_type$",
    personal-relationship-detail = "^testdb.dbo.sccv_personal_relationship_detail$",
    audit                        = "^testdb.dbo.sccv_audit$",
    allocation                   = "^testdb.dbo.sccv_allocations$",
    email-address                = "^testdb.dbo.dm_email_addresses$",
    deleted-person-record        = "^testdb.dbo.sccv_deleted_person_record$",
    mash-referral                = "^testdb.dbo.ref_mash_referrals$",
    mash-resident                = "^testdb.dbo.ref_mash_residents$",
    person-lookup                = "^testdb.dbo.sccv_persons_lookup$",
    tech-use                     = "^testdb.dbo.dm_tech_use$",
    person-case-status-answer    = "^testdb.dbo.sccv_person_case_status_answers$",
    warning-note                 = "^testdb.dbo.sccv_warning_note$",
    person-record-to-be-deleted  = "^testdb.dbo.sccv_person_record_to_be_deleted$",
    gp-detail                    = "^testdb.dbo.dm_gp_details$",
    personal-relationship        = "^testdb.dbo.sccv_personal_relationship$",
    restrcited-flag-import       = "^testdb.dbo.sccv_cfs_restricted_flag_import$"
  }
}

module "tuomo_data_flow_ingest_test_db_to_tuomo_landin_zone" {
  #create a job per table. Inhgesting all tables in one job is too heavy
  for_each = local.tuomo_data_flow_table_filter_expressions_test_db
  tags     = module.tags.values

  source = "../modules/aws-glue-job"
  #work out how to use departments on development (should be able to use housing for example)
  #department = module.department_housing

  job_name                   = "${local.short_identifier_prefix}Tuomo Test Database Ingestion-${each.key}"
  script_s3_object_key       = aws_s3_bucket_object.ingest_database_tables_via_jdbc_connection.key
  environment                = var.environment
  pydeequ_zip_key            = aws_s3_bucket_object.pydeequ.key
  helper_module_key          = aws_s3_bucket_object.helpers.key
  jdbc_connections           = [module.tuomo_testdb_database_ingestion[0].jdbc_connection_name]
  glue_temp_bucket_id        = module.glue_temp_storage.bucket_id
  glue_scripts_bucket_id     = module.glue_scripts.bucket_id
  spark_ui_output_storage_id = module.spark_ui_output_storage.bucket_id

  job_parameters = {
    "--source_data_database"       = module.tuomo_testdb_database_ingestion[0].ingestion_database_name
    "--s3_ingestion_bucket_target" = "s3://${module.landing_zone.bucket_id}/tuomo-test-db/"
    #ingestion details target must have one additional folder level in order for Athena to be able to analyse it once crawled
    #Athena uses these details for queries 
    "--s3_ingestion_details_target" = "s3://${module.landing_zone.bucket_id}/tuomo-test-db/ingestion-details/"
    "--table_filter_expression"     = each.value
  }
  #these are required since department is not provided
  glue_role_arn = aws_iam_role.glue_role.arn #"global" role/resource
  #glue_scripts_bucket_id = already set above
  #glue_temp_bucket_id = already set above
  #environment = already set above
  #tags = already set above

  #crawler should not be set for landing zone data, data should be available for queries from raw zone onwards only
  #   crawler_details = {
  #     database_name      = module.department_housing.raw_zone_catalog_database_name
  #     s3_target_location = "s3://${module.raw_zone.bucket_id}/housing/"
  #     configuration = jsonencode({
  #       Version = 1.0
  #       Grouping = {
  #         TableLevelConfiguration = 3
  #       }
  #     })
  #   }

  schedule = "cron(46 15 ? * WED *)" #TODO TK: remove schedule after testing
}
