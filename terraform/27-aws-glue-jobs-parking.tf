module "Parking_PCN_Create_Event_log_job" {
    source = "../modules/glue_job??"
    deapartment = "parking"
    job_name = "Parking_PCN_Create_Event_log"
    description = <<EOF
    This job reviews the PCN Events trying to find the LATEST event date for a number of Events (i.e. DVLA Requested, DVLA Received).
    The output is a SINGLE PCN record containing some 30+ fields of Dates.
    The field name identifies what the date field is
    EOF

    workflow_name = "" # optional workflow to add any triggers to 
    # If none of the following are supplied, create an on demand trigger
    trigger_name = "trigger-liberator-jobs" # trigger already exists
    triggered_by_job = "" # create a conditional trigger dependent on this job name
    triggered_by_crawler = "" # create a conditional trigger dependent on this crawler name
    input_parameters = {}
    schedule = "" # Create a scheduled trigger
}


