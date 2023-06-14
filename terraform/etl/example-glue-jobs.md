## Example with parking job
```
module "Parking_PCN_Create_Event_log_job" {
  source          = "../modules/glue_job??"
  department      = module.department_parking
  job_name        = "Parking_PCN_Create_Event_log" // will include department
  job_description = <<EOF
    This job reviews the PCN Events trying to find the LATEST event date for a number of Events (i.e. DVLA Requested, DVLA Received).
    The output is a SINGLE PCN record containing some 30+ fields of Dates.
    The field name identifies what the date field is
    EOF

  job_parameters = {} # optional
  script_name    = "" # optional. If not given, will work this out from the job name
  workflow_name  = "" # optional workflow to add any triggers to
  # If none of the following are supplied, create an on demand trigger
  trigger_name           = "trigger-liberator-jobs" # trigger already exists
  triggered_by_job       = ""                       # create a conditional trigger dependent on this job name
  triggered_by_crawler   = ""                       # create a conditional trigger dependent on this crawler name
  schedule               = ""                       # Create a scheduled trigger
  glue_scripts_bucket_id = ""                       // s3 bucket id where scripts are stored
  crawler_details = {
    database_name      = "" // name of the database to store crawled tables
    s3_target_location = "" // s3 location to crawl
  }
}
```
## Example with parking job that is triggered by another job
```
module "Parking_PCN_Create_Event_log_job" {
  source          = "../modules/glue_job??"
  department      = module.department_parking
  job_name        = "Parking_PCN_Create_Event_log"
  job_description = <<EOF
    This job reviews the PCN Events trying to find the LATEST event date for a number of Events (i.e. DVLA Requested, DVLA Received).
    The output is a SINGLE PCN record containing some 30+ fields of Dates.
    The field name identifies what the date field is
    EOF

  job_parameters = {}                                            # optional
  script_name    = ""                                            # optional. If not given, will work this out from the job name
  workflow_name  = aws_glue_workflow.parking_liberator_data.name # optional workflow to add any triggers to
  # If none of the following are supplied, create an on demand trigger
  trigger_name           = ""
  triggered_by_job       = module.Parking_PCN_Create_Event_log_job.job_name # create a conditional trigger dependent on this job name
  triggered_by_crawler   = ""                                               # create a conditional trigger dependent on this crawler name
  schedule               = ""                                               # Create a scheduled trigger
  glue_scripts_bucket_id = ""                                               // s3 bucket id where scripts are stored
  crawler_details = {
    database_name      = "" // name of the database to store crawled tables
    s3_target_location = "" // s3 location to crawl
  }
}
```

## Example with analyst job that requires job parameters to be set
```
module "Address_cleaning" {
  source          = "../modules/glue_job??"
  department      = module.department_data_and_insight
  job_name        = "Address_cleaning"
  job_description = <<EOF
    This job standardises column names and sets appropriate column data types
    EOF

  job_parameters = {
    catalog_database                   = module.department_housing_repairs.raw_zone_catalog_database_name
    refined_zone_catalog_database_name = module.department_housing_repairs.refined_zone_catalog_database_name
    dataset_name                       = "lift-breakdown-ela"
    address_cleaning_script_key        = aws_s3_object.address_cleaning.key
    address_matching_script_key        = aws_s3_object.levenshtein_address_matching.key
    addresses_api_data_catalog         = aws_glue_catalog_database.raw_zone_unrestricted_address_api.name
    trusted_zone_bucket_id             = module.trusted_zone.bucket_id
    match_to_property_shell            = "force"
  }
  script_name   = ""                                            # optional. If not given, will work this out from the job name
  workflow_name = aws_glue_workflow.parking_liberator_data.name # optional workflow to add any triggers to
  # If none of the following are supplied, create an on demand trigger
  trigger_name           = ""
  triggered_by_job       = module.Parking_PCN_Create_Event_log_job.job_name # create a conditional trigger dependent on this job name
  triggered_by_crawler   = ""                                               # create a conditional trigger dependent on this crawler name
  schedule               = ""                                               # Create a scheduled trigger
  glue_scripts_bucket_id = ""                                               // s3 bucket id where scripts are stored
  crawler_details = {
    database_name      = "" // name of the database to store crawled tables
    s3_target_location = "" // s3 location to crawl
  }
}
```



