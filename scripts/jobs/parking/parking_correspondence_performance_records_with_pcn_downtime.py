import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
environment = get_glue_env_var("environment")

# Script generated for node parking_raw_zone - parking_correspondence_performance_teams
parking_raw_zoneparking_correspondence_performance_teams_node1682353072411 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="parking_correspondence_performance_teams",
    transformation_ctx="parking_raw_zoneparking_correspondence_performance_teams_node1682353072411",
)

# Script generated for node S3 bucket  - Raw - liberator_pcn_ic
S3bucketRawliberator_pcn_ic_node1682353070282 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="liberator_pcn_ic",
    transformation_ctx="S3bucketRawliberator_pcn_ic_node1682353070282",
)

# Script generated for node Amazon S3 - refined - pcnfoidetails_pcn_foi_full
AmazonS3refinedpcnfoidetails_pcn_foi_full_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3refinedpcnfoidetails_pcn_foi_full_node1",
)

# Script generated for node parking_raw_zone - parking_officer_downtime
parking_raw_zoneparking_officer_downtime_node1697211483070 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="parking_officer_downtime",
    transformation_ctx="parking_raw_zoneparking_officer_downtime_node1697211483070",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*
Correspondence Performance records last 13 months with PCN FOI records
16/06/2022 - Created 
21/04/2023 - added teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing
02/10/2023 - modified to union data into one output for Downtime data gathered from Google form https://forms.gle/bB53jAayiZ2Ykwjk6
06/11/2024 - updated date formats in downtime data as source google sheet changed to yyyy-mm-dd HH:MM:ss from d/m/y
28/11/2024 - updated downtime records for t_team details to pull from parking_correspondence_performance_teams instead on leaving blank
*/

/*Teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing*/
With team as (
select distinct start_date as t_start_date
,end_date   as t_end_date
,team   as t_team
,team_name   as t_team_name
,role   as t_role
,forename   as t_forename
,surname   as t_surname
,full_name   as t_full_name
,qa_doc_created_by   as t_qa_doc_created_by
,qa_doc_full_name   as t_qa_doc_full_name
,post_title   as t_post_title
,notes  as t_notes
,import_date   as t_import_date--* 
from parking_correspondence_performance_teams where import_date = (select max(parking_correspondence_performance_teams.import_date)  from parking_correspondence_performance_teams ) 
)

select 

/*Fields for union downtime data*/ 
'' as downtime_timestamp
,'' as downtime_email_address
,'' as officer_s_first_name
,'' as officer_s_last_name
,'' as liberator_system_username
,'' as liberator_system_id
,'' as import_datetime
,'' as multiple_downtime_days_flag
,'' as response_secs
,'' as response_mins
,'' as response_hours
,'' as response_days_plus_one
,'' as downtime_total_non_working_mins_with_lunch
, '' as downtime_total_non_working_mins
,'' as downtime_total_working_mins_with_lunch
,'' as downtime_total_working_mins
,'' as downtime_total_working_mins_with_lunch_net
,''  as downtime_total_working_mins_net
, '' as start_date_time
,'' as startdate
,'' as start_date_datetime
,'' as end_date_time
,'' as enddate
,'' as end_date_datetime

/*Liberator Incoming Correspondence Data*/
,case
when liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' then 'Unassigned'
when liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = ''  then 'Assigned'
when liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != ''  then 'Responded'
end as response_status,
cast(current_timestamp as string) as Current_time_stamp,
cast(Case when  liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' then current_timestamp - cast( liberator_pcn_ic.date_received as timestamp)  end as string) as unassigned_time,
cast(Case when  liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' then cast( liberator_pcn_ic.whenassigned as timestamp) - cast( liberator_pcn_ic.date_received as timestamp)  end as string) as to_assigned_time,
cast(Case when liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' then  current_timestamp - cast( liberator_pcn_ic.whenassigned as timestamp) end as string) as assigned_in_progress_time,
cast(Case when liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' then  cast( liberator_pcn_ic.Response_generated_at as timestamp) - cast( liberator_pcn_ic.whenassigned as timestamp) end as string) as assigned_response_time,
cast(Case when liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' then cast( liberator_pcn_ic.Response_generated_at as timestamp) - cast( liberator_pcn_ic.date_received as timestamp) end as string) as response_time,

/*unassigned days*/
cast(Case when  liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' then datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)  )  end as string) as unassigned_days,
Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) <= 5 Then '5 or Less days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff(current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) >= 6 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) ))  <=14 Then '6 to 14 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff(current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) >= 15 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) ))  <=47 Then '15 to 47 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) >= 48 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) ))  <=56 Then '48 to 56 days' 
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) > 56 Then '56 plus days'
end as unassigned_days_group
,cast(Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) <= 56 Then 1  ELSE 0 END as string) as unassigned_days_kpiTotFiftySixLess
,cast(Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff(current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) <= 14 Then 1  ELSE 0 END as string) as unassigned_days_kpiTotFourteenLess,

/*Days to assign*/
cast(Case when  liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' then  datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)) end as string) as Days_to_assign,
Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 5 Then '5 or Less days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 6 AND (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=14 Then '6 to 14 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 15 AND (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=47 Then '15 to 47 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 48 AND (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) > 56 Then '56 plus days'
end as Days_to_assign_group
,cast(Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 56 Then 1  ELSE 0 END as string) as Days_to_assign_kpiTotFiftySixLess
,cast(Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 14 Then 1  ELSE 0 END as string) as Days_to_assign_kpiTotFourteenLess,
    
/*assigned in progress days*/
cast(Case when liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' then  datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ) end as string) as assigned_in_progress_days,
Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <= 5 Then '5 or Less days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  >= 6 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <=14 Then '6 to 14 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  >= 15 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <=47 Then '15 to 47 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  >= 48 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  > 56 Then '56 plus days'
end as assigned_in_progress_days_group
,cast(Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff(current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  <= 56 Then 1  ELSE 0 END as string) as assigned_in_progress_days_kpiTotFiftySixLess
,cast(Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  <= 14 Then 1  ELSE 0 END as string) as assigned_in_progress_days_kpiTotFourteenLess,
    
/*assigned response days*/
cast(Case when liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' then  datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))  end as string) as assignedResponseDays,
Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date)))  <= 5 Then '5 or Less days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) >= 6 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <=14 Then '6 to 14 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) >= 15 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <=47 Then '15 to 47 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) >= 48 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) > 56 Then '56 plus days'
end as assignedResponseDays_group
,cast(Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <= 56 Then 1  ELSE 0 END as string) as assignedResponseDays_kpiTotFiftySixLess
,cast(Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <= 14 Then 1  ELSE 0 END as string) as assignedResponseDays_kpiTotFourteenLess,
    
/*Response days*/
cast(Case when liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' then  datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)) end as string) as ResponseDays,
Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 5 Then '5 or Less days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 6 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=14 Then '6 to 14 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 15 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=47 Then '15 to 47 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 48 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) > 56 Then '56 plus days'
end as ResponseDays_group
,cast(Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff(cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 56 Then 1  ELSE 0 END as string) as ResponseDays_kpiTotFiftySixLess
,cast(Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 14 Then 1  ELSE 0 END as string) as ResponseDays_kpiTotFourteenLess

,Response_generated_at
,Date_Received
,concat(substr(Cast(liberator_pcn_ic.date_received as varchar(10)),1, 7), '-01') as MonthYear  
,liberator_pcn_ic.Type
,Serviceable
,Service_category
,Response_written_by
,Letter_template
,Action_taken
,Related_to_PCN
,Cancellation_group
,Cancellation_reason
,whenassigned
,ticketserialnumber
,noderef
,cast(liberator_pcn_ic.record_created as string) as record_created
,liberator_pcn_ic.import_timestamp
,liberator_pcn_ic.import_year
,liberator_pcn_ic.import_month
,liberator_pcn_ic.import_day
,liberator_pcn_ic.import_date

/*pcn data*/
,pcnfoidetails_pcn_foi_full.pcn as pcn_pcn
,cast(pcnfoidetails_pcn_foi_full.pcnissuedate as string) as pcn_pcnissuedate
,cast(pcnfoidetails_pcn_foi_full.pcnissuedatetime as string) as pcn_pcnissuedatetime
,cast(pcnfoidetails_pcn_foi_full.pcn_canx_date as string) as pcn_pcn_canx_date
,pcnfoidetails_pcn_foi_full.cancellationgroup as pcn_cancellationgroup
,pcnfoidetails_pcn_foi_full.cancellationreason as pcn_cancellationreason
,cast(pcnfoidetails_pcn_foi_full.pcn_casecloseddate as string) as pcn_pcn_casecloseddate
,pcnfoidetails_pcn_foi_full.street_location as pcn_street_location
,pcnfoidetails_pcn_foi_full.whereonlocation as pcn_whereonlocation
,pcnfoidetails_pcn_foi_full.zone as pcn_zone
,pcnfoidetails_pcn_foi_full.usrn as pcn_usrn
,pcnfoidetails_pcn_foi_full.contraventioncode as pcn_contraventioncode
,pcnfoidetails_pcn_foi_full.contraventionsuffix as pcn_contraventionsuffix
,pcnfoidetails_pcn_foi_full.debttype as pcn_debttype
,pcnfoidetails_pcn_foi_full.vrm as pcn_vrm
,pcnfoidetails_pcn_foi_full.vehiclemake as pcn_vehiclemake
,pcnfoidetails_pcn_foi_full.vehiclemodel as pcn_vehiclemodel
,pcnfoidetails_pcn_foi_full.vehiclecolour as pcn_vehiclecolour
,pcnfoidetails_pcn_foi_full.ceo as pcn_ceo
,pcnfoidetails_pcn_foi_full.ceodevice as pcn_ceodevice
,cast(pcnfoidetails_pcn_foi_full.current_30_day_flag as string) as pcn_current_30_day_flag
,cast(pcnfoidetails_pcn_foi_full.isvda as string) as pcn_isvda
,cast(pcnfoidetails_pcn_foi_full.isvoid as string) as pcn_isvoid
,pcnfoidetails_pcn_foi_full.isremoval as pcn_isremoval
,pcnfoidetails_pcn_foi_full.driverseen as pcn_driverseen
,pcnfoidetails_pcn_foi_full.allwindows as pcn_allwindows
,pcnfoidetails_pcn_foi_full.parkedonfootway as pcn_parkedonfootway
,pcnfoidetails_pcn_foi_full.doctor as pcn_doctor
,cast(pcnfoidetails_pcn_foi_full.warningflag as string) as pcn_warningflag
,pcnfoidetails_pcn_foi_full.progressionstage as pcn_progressionstage
,pcnfoidetails_pcn_foi_full.nextprogressionstage as pcn_nextprogressionstage
,pcnfoidetails_pcn_foi_full.nextprogressionstagestarts as pcn_nextprogressionstagestarts
,pcnfoidetails_pcn_foi_full.holdreason as pcn_holdreason
,pcnfoidetails_pcn_foi_full.lib_initial_debt_amount as pcn_lib_initial_debt_amount
,pcnfoidetails_pcn_foi_full.lib_payment_received as pcn_lib_payment_received
,pcnfoidetails_pcn_foi_full.lib_write_off_amount as pcn_lib_write_off_amount
,pcnfoidetails_pcn_foi_full.lib_payment_void as pcn_lib_payment_void
,pcnfoidetails_pcn_foi_full.lib_payment_method as pcn_lib_payment_method
,pcnfoidetails_pcn_foi_full.lib_payment_ref as pcn_lib_payment_ref
,pcnfoidetails_pcn_foi_full.baliff_from as pcn_baliff_from
,pcnfoidetails_pcn_foi_full.bailiff_to as pcn_bailiff_to
,cast(pcnfoidetails_pcn_foi_full.bailiff_processedon as string) as pcn_bailiff_processedon
,pcnfoidetails_pcn_foi_full.bailiff_redistributionreason as pcn_bailiff_redistributionreason
,pcnfoidetails_pcn_foi_full.bailiff as pcn_bailiff
,cast(pcnfoidetails_pcn_foi_full.warrantissuedate as string) as pcn_warrantissuedate
,cast(pcnfoidetails_pcn_foi_full.allocation as string) as pcn_allocation
,cast(pcnfoidetails_pcn_foi_full.eta_datenotified as string) as pcn_eta_datenotified
,cast(pcnfoidetails_pcn_foi_full.eta_packsubmittedon as string) as pcn_eta_packsubmittedon
,cast(pcnfoidetails_pcn_foi_full.eta_evidencedate as string) as pcn_eta_evidencedate
,cast(pcnfoidetails_pcn_foi_full.eta_adjudicationdate as string) as pcn_eta_adjudicationdate
,pcnfoidetails_pcn_foi_full.eta_appealgrounds as pcn_eta_appealgrounds
,cast(pcnfoidetails_pcn_foi_full.eta_decisionreceived as string) as pcn_eta_decisionreceived
,pcnfoidetails_pcn_foi_full.eta_outcome as pcn_eta_outcome
,pcnfoidetails_pcn_foi_full.eta_packsubmittedby as pcn_eta_packsubmittedby
,pcnfoidetails_pcn_foi_full.cancelledby as pcn_cancelledby
,pcnfoidetails_pcn_foi_full.registered_keeper_address as pcn_registered_keeper_address
,pcnfoidetails_pcn_foi_full.current_ticket_address as pcn_current_ticket_address
,cast(pcnfoidetails_pcn_foi_full.corresp_dispute_flag as string) as pcn_corresp_dispute_flag
,cast(pcnfoidetails_pcn_foi_full.keyworker_corresp_dispute_flag as string) as pcn_keyworker_corresp_dispute_flag
,pcnfoidetails_pcn_foi_full.fin_year_flag as pcn_fin_year_flag
,pcnfoidetails_pcn_foi_full.fin_year as pcn_fin_year
,pcnfoidetails_pcn_foi_full.ticket_ref as pcn_ticket_ref
,cast(pcnfoidetails_pcn_foi_full.nto_printed as string) as pcn_nto_printed
,cast(pcnfoidetails_pcn_foi_full.appeal_accepted as string) as pcn_appeal_accepted
,cast(pcnfoidetails_pcn_foi_full.arrived_in_pound as string) as pcn_arrived_in_pound
,cast(pcnfoidetails_pcn_foi_full.cancellation_reversed as string) as pcn_cancellation_reversed
,cast(pcnfoidetails_pcn_foi_full.cc_printed as string) as pcn_cc_printed
,cast(pcnfoidetails_pcn_foi_full.drr as string) as pcn_drr
,cast(pcnfoidetails_pcn_foi_full.en_printed as string) as pcn_en_printed
,cast(pcnfoidetails_pcn_foi_full.hold_released as string) as pcn_hold_released
,cast(pcnfoidetails_pcn_foi_full.dvla_response as string) as pcn_dvla_response
,cast(pcnfoidetails_pcn_foi_full.dvla_request as string) as pcn_dvla_request
,cast(pcnfoidetails_pcn_foi_full.full_rate_uplift as string) as pcn_full_rate_uplift
,cast(pcnfoidetails_pcn_foi_full.hold_until as string) as pcn_hold_until
,cast(pcnfoidetails_pcn_foi_full.lifted_at as string) as pcn_lifted_at
,cast(pcnfoidetails_pcn_foi_full.lifted_by as string) as pcn_lifted_by
,cast(pcnfoidetails_pcn_foi_full.loaded as string) as pcn_loaded
,cast(pcnfoidetails_pcn_foi_full.nor_sent as string) as pcn_nor_sent
,cast(pcnfoidetails_pcn_foi_full.notice_held as string) as pcn_notice_held
,cast(pcnfoidetails_pcn_foi_full.ofr_printed as string) as pcn_ofr_printed
,cast(pcnfoidetails_pcn_foi_full.pcn_printed as string) as pcn_pcn_printed
,cast(pcnfoidetails_pcn_foi_full.reissue_nto_requested as string) as pcn_reissue_nto_requested
,cast(pcnfoidetails_pcn_foi_full.reissue_pcn as string) as pcn_reissue_pcn
,cast(pcnfoidetails_pcn_foi_full.set_back_to_pre_cc_stage as string) as pcn_set_back_to_pre_cc_stage
,cast(pcnfoidetails_pcn_foi_full.vehicle_released_for_auction as string) as pcn_vehicle_released_for_auction 
,cast(pcnfoidetails_pcn_foi_full.warrant_issued as string) as pcn_warrant_issued
,cast(pcnfoidetails_pcn_foi_full.warrant_redistributed as string) as pcn_warrant_redistributed
,cast(pcnfoidetails_pcn_foi_full.warrant_request_granted as string) as pcn_warrant_request_granted
,cast(pcnfoidetails_pcn_foi_full.ad_hoc_vq4_request as string) as pcn_ad_hoc_vq4_request
,cast(pcnfoidetails_pcn_foi_full.paper_vq5_received as string) as pcn_paper_vq5_received
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_buslane as string) as pcn_pcn_extracted_for_buslane
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_pre_debt as string) as pcn_pcn_extracted_for_pre_debt
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_collection as string) as pcn_pcn_extracted_for_collection
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_drr as string) as pcn_pcn_extracted_for_drr
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_cc as string) as pcn_pcn_extracted_for_cc
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_nto as string) as pcn_pcn_extracted_for_nto
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_print as string) as pcn_pcn_extracted_for_print 
,cast(pcnfoidetails_pcn_foi_full.warning_notice_extracted_for_print as string) as pcn_warning_notice_extracted_for_print
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_ofr as string) as pcn_pcn_extracted_for_ofr
,cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_warrant_request as string) as pcn_pcn_extracted_for_warrant_request
,cast(pcnfoidetails_pcn_foi_full.pre_debt_new_debtor_details as string) as pcn_pre_debt_new_debtor_details
,cast(pcnfoidetails_pcn_foi_full.importdattime as string) as pcn_importdattime
,cast(pcnfoidetails_pcn_foi_full.importdatetime as string) as pcn_importdatetime --
,pcnfoidetails_pcn_foi_full.import_year as pcn_import_year
,pcnfoidetails_pcn_foi_full.import_month as pcn_import_month
,pcnfoidetails_pcn_foi_full.import_day as pcn_import_day
,pcnfoidetails_pcn_foi_full.import_date as pcn_import_date

/*Teams data*/
,t_start_date
,t_end_date
,t_team
,t_team_name
,t_role
,t_forename
,t_surname
,t_full_name
,t_qa_doc_created_by
,t_qa_doc_full_name
,t_post_title
,t_notes
,t_import_date

from liberator_pcn_ic
left join pcnfoidetails_pcn_foi_full on liberator_pcn_ic.ticketserialnumber =  pcnfoidetails_pcn_foi_full.pcn and  pcnfoidetails_pcn_foi_full.import_date = liberator_pcn_ic.import_date
left join team on upper(team.t_full_name) = upper(liberator_pcn_ic.Response_written_by)

where liberator_pcn_ic.import_Date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic)
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)  > current_date  - interval '13' month  --Last 13 months from todays date

UNION

--Downtime data gathered from Google form https://forms.gle/bB53jAayiZ2Ykwjk6
Select
cast(parking_officer_downtime.timestamp as string) as downtime_timestamp
,email_address as downtime_email_address
,TRIM(officer_s_first_name) as officer_s_first_name 
,TRIM(officer_s_last_name) as officer_s_last_name
,liberator_system_username
,liberator_system_id
,cast(import_datetime as string) import_datetime
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60)  > 1440 then 1 else 0 end as string) as multiple_downtime_days_flag
,cast(unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')) as string) as response_secs
,cast(Case when parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' then (unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60  end as string) as response_mins
,cast(Case when parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' then (unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/3600  end as string) as response_hours

/*Downtime calendar days*/
,cast(Case when parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' then datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1  end as string) as response_days_plus_one -- downtime days plus one calendar day

/*Downtime non working mins*/
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) > 1440 then /*response_days_plus_one*/(datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1) * 948 
    When parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) < 1440 then 948 end  as string) as downtime_total_non_working_mins_with_lunch --if greater than 1440 mins then (days + 1) * 948  "
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) > 1440 then /*response_days_plus_one*/(datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1) * 1008
    When parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) < 1440 then 1008 end  as string) as downtime_total_non_working_mins --if greater than 1440 mins then (days + 1) * 1008 "

/*Downtime working mins*/
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) > 1440 then /*response_days_plus_one*/(datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1) * 492 
    When parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) < 1440 then 492 end  as string) as downtime_total_working_mins_with_lunch -- 492 mins = 8hrs 12 mins working day including lunch"
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) > 1440 then /*response_days_plus_one*/(datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1) * 432
    When parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) < 1440 then 432 end  as string)  as downtime_total_working_mins --432 mins = 7hrs 12mins working hours"

/*Downtime working mins net (less downtime mins)*/
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) > 1440 then /*response_days_plus_one*/(datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1) * 492
    When parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) < 1440 then 492 - /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) end  as string) as downtime_total_working_mins_with_lunch_net -- 492 mins = 8hrs 12 mins working day including lunch less downtime"
,cast(case when  parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) > 1440 then /*response_days_plus_one*/(datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )+1) * 432
    When parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' and /* downtime mins (response_mins)*/ ((unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60 ) < 1440 then 432 - (/* downtime mins (response_mins)*/ (unix_timestamp(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss')) - unix_timestamp(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss')))/60  ) end  as string) as downtime_total_working_mins_net --432 mins = 7hrs 12mins working hours"

,cast(substr(cast(start_date as string), 12, 5)  as string) as start_date_time
,cast(substr(cast(start_date as string), 1, 10)  as string) as startdate
,cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,16)  as string) as start_date_datetime
,cast(substr(cast(end_date as string), 12, 5)  as string) as end_date_time
,cast(substr(cast(end_date as string), 1, 10)  as string) as enddate
,cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,16)  as string) as end_date_datetime
,'Downtime' as response_status
,cast(current_timestamp as string) as Current_time_stamp

/*Liberator Incoming Correspondence Data*/
,'' as unassigned_time
,'' as to_assigned_time
,'' as assigned_in_progress_time
,'' as assigned_response_time
,(cast (cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,16)  as timestamp) - cast ( Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,16) as timestamp) as string)  )  as response_time --as downtime_duration  --line 30
,'' as unassigned_days
,'' as unassigned_days_group
,'' as unassigned_days_kpiTotFiftySixLess
,'' as unassigned_days_kpiTotFourteenLess
,'' as Days_to_assign
,'' as Days_to_assign_group
,'' as Days_to_assign_kpiTotFiftySixLess
,'' as Days_to_assign_kpiTotFourteenLess
,'' as assigned_in_progress_days
,'' as assigned_in_progress_days_group
,'' as assigned_in_progress_days_kpiTotFiftySixLess
,'' as assigned_in_progress_days_kpiTotFourteenLess
,'' as assignedResponseDays
,'' as assignedResponseDays_group
,'' as assignedResponseDays_kpiTotFiftySixLess
,'' as assignedResponseDays_kpiTotFourteenLess
,cast( Case when parking_officer_downtime.timestamp not like '' and parking_officer_downtime.timestamp not like '#REF!' then datediff( cast(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date), cast(Substr(cast(to_timestamp(start_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,10) as date) )  end as string) as ResponseDays --as downtime_duration in days
,'' as ResponseDays_group
,'' as ResponseDays_kpiTotFiftySixLess
,'' as ResponseDays_kpiTotFourteenLess
, end_date as Response_generated_at
, start_date  as Date_Received
,concat(Substr(cast(to_timestamp(end_date,'yyyy-MM-dd HH:mm:ss') as varchar(30)),1,7), '-01') as MonthYear  
,'Downtime' as  Type
,parking_officer_downtime.Downtime as Serviceable -- downtime
,'' as Service_category
,concat(TRIM(officer_s_first_name),' ',TRIM(officer_s_last_name)) as Response_written_by --downtime officer full name
,'' as Letter_template
,'' as Action_taken
,'' as Related_to_PCN
,'' as Cancellation_group
,'' as Cancellation_reason
,'' as whenassigned
,'' as ticketserialnumber
,'' as noderef
,'' as record_created  
,import_timestamp
,import_year
,import_month
,import_day
,cast(import_date as string) as import_date

/*pcn data*/
,'' as  pcn_pcn
,'' as  pcn_pcnissuedate
,'' as  pcn_pcnissuedatetime --line 74
,'' as  pcn_pcn_canx_date
,'' as  pcn_cancellationgroup
,'' as  pcn_cancellationreason
,'' as  pcn_pcn_casecloseddate
,'' as  pcn_street_location
,'' as  pcn_whereonlocation
,'' as  pcn_zone
,'' as  pcn_usrn
,'' as  pcn_contraventioncode
,'' as  pcn_contraventionsuffix
,'' as  pcn_debttype
,'' as  pcn_vrm
,'' as  pcn_vehiclemake
,'' as  pcn_vehiclemodel
,'' as  pcn_vehiclecolour
,'' as  pcn_ceo
,'' as  pcn_ceodevice
,'' as  pcn_current_30_day_flag
,'' as  pcn_isvda
,'' as  pcn_isvoid
,'' as  pcn_isremoval
,'' as  pcn_driverseen
,'' as  pcn_allwindows
,'' as  pcn_parkedonfootway
,'' as  pcn_doctor
,'' as  pcn_warningflag
,'' as  pcn_progressionstage
,'' as  pcn_nextprogressionstage --100
,'' as  pcn_nextprogressionstagestarts
,'' as  pcn_holdreason
,'' as  pcn_lib_initial_debt_amount
,'' as  pcn_lib_payment_received
,'' as  pcn_lib_write_off_amount
,'' as  pcn_lib_payment_void
,'' as  pcn_lib_payment_method
,'' as  pcn_lib_payment_ref
,'' as  pcn_baliff_from
,'' as  pcn_bailiff_to
,'' as  pcn_bailiff_processedon
,'' as  pcn_bailiff_redistributionreason
,'' as  pcn_bailiff
,'' as  pcn_warrantissuedate
,'' as  pcn_allocation
,''  as  pcn_eta_datenotified
,''  as  pcn_eta_packsubmittedon
,''  as  pcn_eta_evidencedate
,'' as  pcn_eta_adjudicationdate
,'' as  pcn_eta_appealgrounds
,''  as  pcn_eta_decisionreceived
,'' as  pcn_eta_outcome
,'' as  pcn_eta_packsubmittedby
,'' as  pcn_cancelledby
,'' as  pcn_registered_keeper_address
,'' as  pcn_current_ticket_address
,'' as  pcn_corresp_dispute_flag
,'' as  pcn_keyworker_corresp_dispute_flag
,'' as  pcn_fin_year_flag
,'' as  pcn_fin_year
,'' as  pcn_ticket_ref
,''  as  pcn_nto_printed
,''  as  pcn_appeal_accepted
,''  as  pcn_arrived_in_pound
,''  as  pcn_cancellation_reversed
,''  as  pcn_cc_printed
,''  as  pcn_drr
,''  as  pcn_en_printed
,''  as  pcn_hold_released
,''  as  pcn_dvla_response
,''  as  pcn_dvla_request
,''  as  pcn_full_rate_uplift
,''  as  pcn_hold_until
,''  as  pcn_lifted_at
,''  as  pcn_lifted_by
,''  as  pcn_loaded
,''  as  pcn_nor_sent
,''  as  pcn_notice_held
,''  as  pcn_ofr_printed
,'' as  pcn_pcn_printed
,''  as  pcn_reissue_nto_requested
,''  as  pcn_reissue_pcn
,''  as  pcn_set_back_to_pre_cc_stage
,''  as  pcn_vehicle_released_for_auction
,''  as  pcn_warrant_issued
,''  as  pcn_warrant_redistributed
,''  as  pcn_warrant_request_granted
,'' as  pcn_ad_hoc_vq4_request
,''  as  pcn_paper_vq5_received
,''  as  pcn_pcn_extracted_for_buslane
,'' as  pcn_pcn_extracted_for_pre_debt
,''  as  pcn_pcn_extracted_for_collection
,''  as  pcn_pcn_extracted_for_drr
,''  as  pcn_pcn_extracted_for_cc
,''  as  pcn_pcn_extracted_for_nto
,''  as  pcn_pcn_extracted_for_print
,''  as  pcn_warning_notice_extracted_for_print
,''  as  pcn_pcn_extracted_for_ofr
,''  as  pcn_pcn_extracted_for_warrant_request
,''  as  pcn_pre_debt_new_debtor_details
,''  as  pcn_importdattime
,''  as  pcn_importdatetime
,'' as  pcn_import_year
,'' as  pcn_import_month
,'' as  pcn_import_day
,'' as  pcn_import_date

/*Teams data*/
,t_start_date
,t_end_date
,t_team
,t_team_name
,t_role
,t_forename
,t_surname
,t_full_name
,t_qa_doc_created_by
,t_qa_doc_full_name
,t_post_title
,t_notes
,t_import_date

from parking_officer_downtime 
left join team on upper(team.t_full_name) = upper(concat(TRIM(officer_s_first_name),' ',TRIM(officer_s_last_name))) --as Response_written_by --downtime officer full name
where import_date = (select max(import_date) from parking_officer_downtime) and timestamp not like '' and timestamp not like '#REF!'
AND cast(Substr( cast(parking_officer_downtime.timestamp as string) ,1,10) as date)  > current_date  - interval '13' month  --Last 13 months from todays date
--order by timestamp desc
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "pcnfoidetails_pcn_foi_full": AmazonS3refinedpcnfoidetails_pcn_foi_full_node1,
        "liberator_pcn_ic": S3bucketRawliberator_pcn_ic_node1682353070282,
        "parking_correspondence_performance_teams": parking_raw_zoneparking_correspondence_performance_teams_node1682353072411,
        "parking_officer_downtime": parking_raw_zoneparking_officer_downtime_node1697211483070,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node Liberator Refined - parking_correspondence_performance_records_with_pcn
LiberatorRefinedparking_correspondence_performance_records_with_pcn_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_correspondence_performance_records_with_pcn_downtime/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="LiberatorRefinedparking_correspondence_performance_records_with_pcn_node3",
)
LiberatorRefinedparking_correspondence_performance_records_with_pcn_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_correspondence_performance_records_with_pcn_downtime",
)
LiberatorRefinedparking_correspondence_performance_records_with_pcn_node3.setFormat(
    "glueparquet"
)
LiberatorRefinedparking_correspondence_performance_records_with_pcn_node3.writeFrame(
    ApplyMapping_node2
)
job.commit()
