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

# Script generated for node Amazon S3 - refined - pcnfoidetails_pcn_foi_full
AmazonS3refinedpcnfoidetails_pcn_foi_full_node1657284942794 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3refinedpcnfoidetails_pcn_foi_full_node1657284942794",
)

# Script generated for node S3 bucket  - Raw - liberator_pcn_ic
S3bucketRawliberator_pcn_ic_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="liberator_pcn_ic",
    transformation_ctx="S3bucketRawliberator_pcn_ic_node1",
)

# Script generated for node parking_raw_zone - parking_correspondence_performance_teams
parking_raw_zoneparking_correspondence_performance_teams_node1682094127227 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 14)",
    table_name="parking_correspondence_performance_teams",
    transformation_ctx="parking_raw_zoneparking_correspondence_performance_teams_node1682094127227",
)

# Script generated for node SQL
SqlQuery0 = """
/* 
Correspondence Performance records last 13 months with PCN FOI records
16/06/2022 - Created 
30/11/2022 - with totals for Month and response dates for each officer
21/04/2023 - added teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing

*/
With officer_total_rep_dates as(
select
liberator_pcn_ic.Response_written_by as tot_rep_Response_written_by
,substr(liberator_pcn_ic.response_generated_at, 1, 10) as tot_rep_response_date
,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') as tot_rep_monthYear_response
,concat(liberator_pcn_ic.Response_written_by,substr(liberator_pcn_ic.response_generated_at, 1, 10) ) as tot_rep_unique_link

,count (distinct substr(liberator_pcn_ic.response_generated_at, 1, 10)) as tot_rep_total_dates
,count (*) as tot_rep_records


from liberator_pcn_ic
left join pcnfoidetails_pcn_foi_full on liberator_pcn_ic.ticketserialnumber = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = liberator_pcn_ic.import_date

where liberator_pcn_ic.import_Date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic)
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)  > current_date  - interval '13' month  --Last 13 months from todays date

group by
liberator_pcn_ic.Response_written_by --as tot_rep_Response_written_by
,substr(liberator_pcn_ic.response_generated_at, 1, 10) --as tot_rep_response_date
,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') --as tot_rep_monthYear_response
,concat(liberator_pcn_ic.Response_written_by,substr(liberator_pcn_ic.response_generated_at, 1, 10) ) --as tot_rep_unique_link

)
, total_response_month as (
select
liberator_pcn_ic.Response_written_by as mth_tot_rep_Response_written_by
,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') as mth_tot_rep_monthYear_response
,concat(liberator_pcn_ic.Response_written_by,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') ) as mth_tot_rep_unique_link

,count (distinct substr(liberator_pcn_ic.response_generated_at, 1, 10)) as mth_tot_rep_total_dates
,count (*) as mth_tot_rep_records


from liberator_pcn_ic
left join pcnfoidetails_pcn_foi_full on liberator_pcn_ic.ticketserialnumber = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = liberator_pcn_ic.import_date

where liberator_pcn_ic.import_Date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic)
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)  > current_date  - interval '13' month  --Last 13 months from todays date


group by
liberator_pcn_ic.Response_written_by --as mth_tot_rep_Response_written_by
,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') --as mth_tot_rep_monthYear_response
,concat(liberator_pcn_ic.Response_written_by,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') ) --as mth_tot_rep_unique_link
order by 
concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') desc --as mth_tot_rep_monthYear_response

)
, team as (
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
from parking_correspondence_performance_teams where import_date = (select max(import_date)  from parking_correspondence_performance_teams ) 
)


Select  
case
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
cast(Case when  liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' then datediff(current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)  )  end as string) as unassigned_days,
Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) <= 5 Then '5 or Less days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff(current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) >= 6 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) ))  <=14 Then '6 to 14 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) >= 15 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) ))  <=47 Then '15 to 47 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) >= 48 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) ))  <=56 Then '48 to 56 days' 
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) > 56 Then '56 plus days'
end as unassigned_days_group
,Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) <= 56 Then 1  ELSE 0 END as unassigned_days_kpiTotFiftySixLess
,Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )) <= 14 Then 1  ELSE 0 END as unassigned_days_kpiTotFourteenLess,

/*Days to assign*/
cast(Case when  liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' then  datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)) end as string) as Days_to_assign,
Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 5 Then '5 or Less days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 6 AND (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=14 Then '6 to 14 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 15 AND (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=47 Then '15 to 47 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 48 AND (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) > 56 Then '56 plus days'
end as Days_to_assign_group
,Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 56 Then 1  ELSE 0 END as Days_to_assign_kpiTotFiftySixLess
,Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.whenassigned != '' and  (datediff( cast(substr( liberator_pcn_ic.whenassigned, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 14 Then 1  ELSE 0 END as Days_to_assign_kpiTotFourteenLess,
    
/*assigned in progress days*/
cast(Case when liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' then  datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ) end as string) as assigned_in_progress_days,
Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <= 5 Then '5 or Less days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  >= 6 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <=14 Then '6 to 14 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  >= 15 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <=47 Then '15 to 47 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  >= 48 AND (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) )) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  > 56 Then '56 plus days'
end as assigned_in_progress_days_group
,Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  <= 56 Then 1  ELSE 0 END as assigned_in_progress_days_kpiTotFiftySixLess
,Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at = '' and (datediff( current_timestamp, cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date) ))  <= 14 Then 1  ELSE 0 END as assigned_in_progress_days_kpiTotFourteenLess,
    
/*assigned response days*/
cast(Case when liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' then  datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))  end as string) as assignedResponseDays,
Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date)))  <= 5 Then '5 or Less days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) >= 6 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <=14 Then '6 to 14 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) >= 15 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <=47 Then '15 to 47 days'
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) >= 48 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) > 56 Then '56 plus days'
end as assignedResponseDays_group
,Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <= 56 Then 1  ELSE 0 END as assignedResponseDays_kpiTotFiftySixLess
,Case When liberator_pcn_ic.whenassigned != '' AND liberator_pcn_ic.response_generated_at != '' and (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.whenassigned, 1, 10) as date))) <= 14 Then 1  ELSE 0 END as assignedResponseDays_kpiTotFourteenLess,
    
/*Response days*/
cast(Case when liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' then  datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)) end as string) as ResponseDays,
Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 5 Then '5 or Less days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 6 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=14 Then '6 to 14 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 15 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=47 Then '15 to 47 days'
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) >= 48 AND (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <=56 Then '48 to 56 days' 
When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) > 56 Then '56 plus days'
end as ResponseDays_group
,Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 56 Then 1  ELSE 0 END as ResponseDays_kpiTotFiftySixLess
,Case When liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != '' and  (datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date))) <= 14 Then 1  ELSE 0 END as ResponseDays_kpiTotFourteenLess,

Response_generated_at
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
,substr(cast(liberator_pcn_ic.record_created as string), 1, 19) as record_created
,substr(cast(liberator_pcn_ic.import_timestamp as string), 1, 19) as import_timestamp
,substr(cast(liberator_pcn_ic.import_year as string), 1, 04) as import_year
,substr(cast(liberator_pcn_ic.import_month as string), 1, 02) as import_month
,liberator_pcn_ic.import_day
,substr(cast(liberator_pcn_ic.import_date as string), 1, 08) as import_date

/*pcn data*/
,pcnfoidetails_pcn_foi_full.pcn as pcn_pcn
,substr(cast(pcnfoidetails_pcn_foi_full.pcnissuedate as string), 1, 10)  as pcn_pcnissuedate
,substr(cast(pcnfoidetails_pcn_foi_full.pcnissuedatetime as string), 1, 19)  as pcn_pcnissuedatetime
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_canx_date as string), 1, 10)  as pcn_pcn_canx_date
,pcnfoidetails_pcn_foi_full.cancellationgroup as pcn_cancellationgroup
,pcnfoidetails_pcn_foi_full.cancellationreason as pcn_cancellationreason
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_casecloseddate as string), 1, 10)  as pcn_pcn_casecloseddate
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
,pcnfoidetails_pcn_foi_full.current_30_day_flag as pcn_current_30_day_flag
,pcnfoidetails_pcn_foi_full.isvda as pcn_isvda
,pcnfoidetails_pcn_foi_full.isvoid as pcn_isvoid
,pcnfoidetails_pcn_foi_full.isremoval as pcn_isremoval
,pcnfoidetails_pcn_foi_full.driverseen as pcn_driverseen
,pcnfoidetails_pcn_foi_full.allwindows as pcn_allwindows
,pcnfoidetails_pcn_foi_full.parkedonfootway as pcn_parkedonfootway
,pcnfoidetails_pcn_foi_full.doctor as pcn_doctor
,pcnfoidetails_pcn_foi_full.warningflag as pcn_warningflag
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
,substr(cast(pcnfoidetails_pcn_foi_full.bailiff_processedon as string), 1, 19)  as pcn_bailiff_processedon
,pcnfoidetails_pcn_foi_full.bailiff_redistributionreason as pcn_bailiff_redistributionreason
,pcnfoidetails_pcn_foi_full.bailiff as pcn_bailiff
,substr(cast(pcnfoidetails_pcn_foi_full.warrantissuedate as string), 1, 19)  as pcn_warrantissuedate
,pcnfoidetails_pcn_foi_full.allocation as pcn_allocation
,substr(cast(pcnfoidetails_pcn_foi_full.eta_datenotified as string), 1, 19)  as pcn_eta_datenotified
,substr(cast(pcnfoidetails_pcn_foi_full.eta_packsubmittedon as string), 1, 19)  as pcn_eta_packsubmittedon
,substr(cast(pcnfoidetails_pcn_foi_full.eta_evidencedate as string), 1, 19)  as pcn_eta_evidencedate
,substr(cast(pcnfoidetails_pcn_foi_full.eta_adjudicationdate as string), 1, 19)   as pcn_eta_adjudicationdate
,pcnfoidetails_pcn_foi_full.eta_appealgrounds as pcn_eta_appealgrounds
,pcnfoidetails_pcn_foi_full.eta_decisionreceived as pcn_eta_decisionreceived
,pcnfoidetails_pcn_foi_full.eta_outcome as pcn_eta_outcome
,pcnfoidetails_pcn_foi_full.eta_packsubmittedby as pcn_eta_packsubmittedby
,pcnfoidetails_pcn_foi_full.cancelledby as pcn_cancelledby
,pcnfoidetails_pcn_foi_full.registered_keeper_address as pcn_registered_keeper_address
,pcnfoidetails_pcn_foi_full.current_ticket_address as pcn_current_ticket_address
,pcnfoidetails_pcn_foi_full.corresp_dispute_flag as pcn_corresp_dispute_flag
,pcnfoidetails_pcn_foi_full.keyworker_corresp_dispute_flag as pcn_keyworker_corresp_dispute_flag
,pcnfoidetails_pcn_foi_full.fin_year_flag as pcn_fin_year_flag
,pcnfoidetails_pcn_foi_full.fin_year as pcn_fin_year
,pcnfoidetails_pcn_foi_full.ticket_ref as pcn_ticket_ref
,substr(cast(pcnfoidetails_pcn_foi_full.nto_printed as string), 1, 19) as pcn_nto_printed
,substr(cast(pcnfoidetails_pcn_foi_full.appeal_accepted as string), 1, 19) as pcn_appeal_accepted
,substr(cast(pcnfoidetails_pcn_foi_full.arrived_in_pound as string), 1, 19)  as pcn_arrived_in_pound
,substr(cast(pcnfoidetails_pcn_foi_full.cancellation_reversed as string), 1, 19)  as pcn_cancellation_reversed
,substr(cast(pcnfoidetails_pcn_foi_full.cc_printed as string), 1, 19)  as pcn_cc_printed
,substr(cast(pcnfoidetails_pcn_foi_full.drr as string), 1, 19)  as pcn_drr
,substr(cast(pcnfoidetails_pcn_foi_full.en_printed as string), 1, 19)  as pcn_en_printed
,substr(cast(pcnfoidetails_pcn_foi_full.hold_released as string), 1, 19)  as pcn_hold_released
,substr(cast(pcnfoidetails_pcn_foi_full.dvla_response as string), 1, 19)  as pcn_dvla_response
,substr(cast(pcnfoidetails_pcn_foi_full.dvla_request as string), 1, 19)  as pcn_dvla_request
,substr(cast(pcnfoidetails_pcn_foi_full.full_rate_uplift as string), 1, 19)  as pcn_full_rate_uplift
,substr(cast(pcnfoidetails_pcn_foi_full.hold_until as string), 1, 19)  as pcn_hold_until
,substr(cast(pcnfoidetails_pcn_foi_full.lifted_at as string), 1, 19)  as pcn_lifted_at
,substr(cast(pcnfoidetails_pcn_foi_full.lifted_by as string), 1, 19)  as pcn_lifted_by
,substr(cast(pcnfoidetails_pcn_foi_full.loaded as string), 1, 19)  as pcn_loaded
,substr(cast(pcnfoidetails_pcn_foi_full.nor_sent as string), 1, 19)  as pcn_nor_sent
,substr(cast(pcnfoidetails_pcn_foi_full.notice_held as string), 1, 19)  as pcn_notice_held
,substr(cast(pcnfoidetails_pcn_foi_full.ofr_printed as string), 1, 19)  as pcn_ofr_printed
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_printed as string), 1, 19)  as pcn_pcn_printed
,substr(cast(pcnfoidetails_pcn_foi_full.reissue_nto_requested as string), 1, 19)  as pcn_reissue_nto_requested
,substr(cast(pcnfoidetails_pcn_foi_full.reissue_pcn as string), 1, 19)  as pcn_reissue_pcn
,substr(cast(pcnfoidetails_pcn_foi_full.set_back_to_pre_cc_stage as string), 1, 19)  as pcn_set_back_to_pre_cc_stage
,substr(cast(pcnfoidetails_pcn_foi_full.vehicle_released_for_auction as string), 1, 19)  as pcn_vehicle_released_for_auction
,substr(cast(pcnfoidetails_pcn_foi_full.warrant_issued as string), 1, 19)  as pcn_warrant_issued
,substr(cast(pcnfoidetails_pcn_foi_full.warrant_redistributed as string), 1, 19)  as pcn_warrant_redistributed
,substr(cast(pcnfoidetails_pcn_foi_full.warrant_request_granted as string), 1, 19)  as pcn_warrant_request_granted
,substr(cast(pcnfoidetails_pcn_foi_full.ad_hoc_vq4_request as string), 1, 19)  as pcn_ad_hoc_vq4_request
,substr(cast(pcnfoidetails_pcn_foi_full.paper_vq5_received as string), 1, 19)  as pcn_paper_vq5_received
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_buslane as string), 1, 19)  as pcn_pcn_extracted_for_buslane
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_pre_debt as string), 1, 19)  as pcn_pcn_extracted_for_pre_debt
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_collection as string), 1, 19)  as pcn_pcn_extracted_for_collection
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_drr as string), 1, 19)  as pcn_pcn_extracted_for_drr
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_cc as string), 1, 19)  as pcn_pcn_extracted_for_cc
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_nto as string), 1, 19)  as pcn_pcn_extracted_for_nto
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_print as string), 1, 19)  as pcn_pcn_extracted_for_print
,substr(cast(pcnfoidetails_pcn_foi_full.warning_notice_extracted_for_print as string), 1, 19)  as pcn_warning_notice_extracted_for_print
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_ofr as string), 1, 19)  as pcn_pcn_extracted_for_ofr
,substr(cast(pcnfoidetails_pcn_foi_full.pcn_extracted_for_warrant_request as string), 1, 19)  as pcn_pcn_extracted_for_warrant_request
,substr(cast(pcnfoidetails_pcn_foi_full.pre_debt_new_debtor_details as string), 1, 19)  as pcn_pre_debt_new_debtor_details
,substr(cast(pcnfoidetails_pcn_foi_full.importdattime as string), 1, 19)  as pcn_importdattime
,substr(cast(pcnfoidetails_pcn_foi_full.importdatetime as string), 1, 19)  as pcn_importdatetime
,substr(cast(pcnfoidetails_pcn_foi_full.import_year as string), 1, 04)  as pcn_import_year
,substr(cast(pcnfoidetails_pcn_foi_full.import_month as string), 1, 02)  as pcn_import_month
,pcnfoidetails_pcn_foi_full.import_day as pcn_import_day
,substr(cast(pcnfoidetails_pcn_foi_full.import_date as string), 1, 08)  as pcn_import_date


,concat(liberator_pcn_ic.Response_written_by,substr(liberator_pcn_ic.response_generated_at, 1, 10) ) as link_officer_total_rep_dates
,concat(liberator_pcn_ic.Response_written_by,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') ) as link_month_total

,total_response_month.mth_tot_rep_monthYear_response
,total_response_month.mth_tot_rep_total_dates
,total_response_month.mth_tot_rep_records


,officer_total_rep_dates.tot_rep_response_date
,officer_total_rep_dates.tot_rep_total_dates
,officer_total_rep_dates.tot_rep_records
,team.*

from liberator_pcn_ic
left join pcnfoidetails_pcn_foi_full on liberator_pcn_ic.ticketserialnumber = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = liberator_pcn_ic.import_date

left join officer_total_rep_dates on concat(liberator_pcn_ic.Response_written_by,substr(liberator_pcn_ic.response_generated_at, 1, 10) ) = officer_total_rep_dates.tot_rep_unique_link

left join total_response_month on concat(liberator_pcn_ic.Response_written_by,concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') ) = total_response_month.mth_tot_rep_unique_link

left join team on upper(team.t_full_name) = upper(liberator_pcn_ic.Response_written_by)

where liberator_pcn_ic.import_Date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic)
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)  > current_date  - interval '13' month  --Last 13 months from todays date


"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "pcnfoidetails_pcn_foi_full": AmazonS3refinedpcnfoidetails_pcn_foi_full_node1657284942794,
        "liberator_pcn_ic": S3bucketRawliberator_pcn_ic_node1,
        "parking_correspondence_performance_teams": parking_raw_zoneparking_correspondence_performance_teams_node1682094127227,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_correspondence_performance_records_with_pcn_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_correspondence_performance_records_with_pcn_gds",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()

