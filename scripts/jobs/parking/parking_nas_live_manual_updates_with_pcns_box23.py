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
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
environment = get_glue_env_var("environment")

# Script generated for node parking-refined-zone - parking_nas_live_manual_updates_data_load_with_pcns
parkingrefinedzoneparking_nas_live_manual_updates_data_load_with_pcns_node1718795085627 = glueContext.create_dynamic_frame.from_catalog(database="parking-refined-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="parking_nas_live_manual_updates_data_load_with_pcns", transformation_ctx="parkingrefinedzoneparking_nas_live_manual_updates_data_load_with_pcns_node1718795085627")

# Script generated for node  parking-raw-zone parking_wsbox2_log
parkingrawzoneparking_wsbox2_log_node1718795091088 = glueContext.create_dynamic_frame.from_catalog(database="parking-raw-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="parking_wsbox2_log", transformation_ctx="parkingrawzoneparking_wsbox2_log_node1718795091088")

# Script generated for node parking-raw-zone parking_wsbox3_log
parkingrawzoneparking_wsbox3_log_node1718795088646 = glueContext.create_dynamic_frame.from_catalog(database="parking-raw-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="parking_wsbox3_log", transformation_ctx="parkingrawzoneparking_wsbox3_log_node1718795088646")

# Script generated for node NAS live ETA pcn box23 listagg
SqlQuery0 = '''
/*
NAS live ETA data matched to Liberator PCN data and lISTAGG/pivot to the google sheets Box 2 and Box 3 data 

Data output to be used in google studio dashboard https://lookerstudio.google.com/s/q5XPCwiwBRY or https://lookerstudio.google.com/reporting/22d13bf3-0757-4a97-9de5-04b6a3a9f563
Source Form: Hackney Parkin NAS Live - ETA data: https://forms.gle/Y4c9du6XjJvvEAoQA
Box 2 and Box 3 data source: Updated WS and ETA Appeals Logging Sheet - https://docs.google.com/spreadsheets/d/1Hdha9VXaI6RGVqAHux0GE-_8JpRL5aoNLzSUjlfojqI/edit?usp=sharing

AWS tables:
from "parking-raw-zone".parking_wsbox2_log
from "parking-raw-zone".parking_wsbox3_log
FROM "parking-refined-zone".parking_nas_live_manual_updates_data_load_with_pcns

19/06/2024 - created


change union to the left join box 2 and box 3*/
With box2 as (
select record_number	,date_logged_in_the_ro_logging_sheet	,actual_date_passed_on_to_bpt as date_passed_to_bpt	,last_day_to_present_ep	,pcn	,category	,evidence_pack_created	,good_to_process	,'' as reason	,date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant	,printing_order_number	,officer_initials	,'' as column11	,import_datetime	,import_timestamp	,notes	,import_year	,import_month	,import_day	,import_date

from parking_wsbox2_log where import_date = (select max(import_date)  from parking_wsbox2_log ) order by import_date desc ,pcn 
)
, box3 as (
select record_number	,date_logged_in_the_ro_logging_sheet	,date_passed_to_bpt	,last_day_to_present_ep	,pcn	,category	,'' as evidence_pack_created	,good_to_process	,reason	,date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant	,order_number as printing_order_number	,officer_initials	,'' as column11		,import_datetime	,import_timestamp	,notes	,import_year	,import_month	,import_day	,import_date

from parking_wsbox3_log where import_date = (select max(import_date)  from parking_wsbox3_log )  order by import_date desc ,pcn 
)
, nlpcn as (
SELECT distinct * FROM parking_nas_live_manual_updates_data_load_with_pcns
WHERE import_date = (SELECT max(import_date) from parking_nas_live_manual_updates_data_load_with_pcns)
and pcn_import_date = import_date
order by parking_nas_live_manual_updates_data_load_with_pcns.timestamp desc
)
, nlpcn_box23 as (
Select nlpcn.pcn ,count(box23.pcn) as num_recs
--,LISTAGG(DISTINCT box23.officer_initials, ' ||  ') WITHIN GROUP (ORDER BY box23.officer_initials ) as vl_officer_initials
 ,array_join( -- concat the array
  collect_list(distinct box23.officer_initials), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_officer_initials

--,LISTAGG(DISTINCT box23.date_logged_in_the_ro_logging_sheet, '   ') WITHIN GROUP (ORDER BY box23.date_logged_in_the_ro_logging_sheet ) as vl_multi_date_logged_in_the_ro_logging_sheet
 ,array_join( -- concat the array
  collect_list(distinct box23.date_logged_in_the_ro_logging_sheet), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_date_logged_in_the_ro_logging_sheet
 
--,LISTAGG(DISTINCT box23.date_passed_to_bpt, '   ') WITHIN GROUP (ORDER BY box23.date_passed_to_bpt ) as vl_multi_date_passed_to_bpt
 ,array_join( -- concat the array
  collect_list(distinct box23.date_passed_to_bpt), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_date_passed_to_bpt
 
--,LISTAGG(DISTINCT box23.last_day_to_present_ep, '   ') WITHIN GROUP (ORDER BY box23.last_day_to_present_ep ) as vl_multi_last_day_to_present_ep
 ,array_join( -- concat the array
  collect_list(distinct box23.last_day_to_present_ep), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_last_day_to_present_ep
 
--,LISTAGG(DISTINCT box23.category, '   ') WITHIN GROUP (ORDER BY box23.category ) as vl_multi_category
 ,array_join( -- concat the array
  collect_list(distinct box23.category), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_category
 
--,LISTAGG(DISTINCT box23.evidence_pack_created, '   ') WITHIN GROUP (ORDER BY box23.evidence_pack_created ) as vl_multi_evidence_pack_created
 ,array_join( -- concat the array
  collect_list(distinct box23.evidence_pack_created), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_evidence_pack_created
 
--,LISTAGG(DISTINCT box23.good_to_process, '   ') WITHIN GROUP (ORDER BY box23.good_to_process ) as vl_multi_good_to_process
 ,array_join( -- concat the array
  collect_list(distinct box23.good_to_process), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_good_to_process
 
--,LISTAGG(DISTINCT box23.reason, ' || ') WITHIN GROUP (ORDER BY box23.reason ) as vl_multi_reason
 ,array_join( -- concat the array
  collect_list(distinct box23.reason), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_reason
 
--,LISTAGG(DISTINCT box23.date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant, '   ') WITHIN GROUP (ORDER BY box23.date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant ) as vl_multi_date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant
 ,array_join( -- concat the array
  collect_list(distinct box23.date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant
 
--,LISTAGG(DISTINCT box23.printing_order_number, '   ') WITHIN GROUP (ORDER BY box23.printing_order_number ) as vl_multi_printing_order_number
 ,array_join( -- concat the array
  collect_list(distinct box23.printing_order_number), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_printing_order_number
 
--,LISTAGG(DISTINCT box23.record_number, '   ') WITHIN GROUP (ORDER BY box23.record_number ) as vl_multi_record_number
 ,array_join( -- concat the array
  collect_list(distinct box23.record_number), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_record_number
 

from nlpcn
left join (
select record_number	,date_logged_in_the_ro_logging_sheet	,date_passed_to_bpt	,last_day_to_present_ep	,pcn	,category	,evidence_pack_created	,good_to_process	,reason	,date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant	,printing_order_number	,officer_initials	,column11	,import_datetime	,import_timestamp	,notes	,import_year	,import_month	,import_day	,import_date from box3
union all
select record_number	,date_logged_in_the_ro_logging_sheet	,date_passed_to_bpt	,last_day_to_present_ep	,pcn	,category	,evidence_pack_created	,good_to_process	,reason	,date_actioned_ep_sent_out_to_eta_case_withdrawn_letter_sent_out_to_declarant	,printing_order_number	,officer_initials	,column11	,import_datetime	,import_timestamp	,notes	,import_year	,import_month	,import_day	,import_date from box2
) box23 on box23.pcn = nlpcn.pcn
group by  nlpcn.pcn
)
select nlpcn.* ,nlpcn_box23.*
from nlpcn
left join nlpcn_box23 on nlpcn_box23.pcn = nlpcn.pcn
order by nlpcn.pcn
'''
NASliveETApcnbox23listagg_node1718795096016 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"parking_wsbox2_log":parkingrawzoneparking_wsbox2_log_node1718795091088, "parking_wsbox3_log":parkingrawzoneparking_wsbox3_log_node1718795088646, "parking_nas_live_manual_updates_data_load_with_pcns":parkingrefinedzoneparking_nas_live_manual_updates_data_load_with_pcns_node1718795085627}, transformation_ctx = "NASliveETApcnbox23listagg_node1718795096016")

# Script generated for node parking refined - parking_nas_live_manual_updates_with_pcns_box23
parkingrefinedparking_nas_live_manual_updates_with_pcns_box23_node1718795102868 = glueContext.getSink(path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_nas_live_manual_updates_with_pcns_box23/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=["import_year", "import_month", "import_day", "import_date"], enableUpdateCatalog=True, transformation_ctx="parkingrefinedparking_nas_live_manual_updates_with_pcns_box23_node1718795102868")
parkingrefinedparking_nas_live_manual_updates_with_pcns_box23_node1718795102868.setCatalogInfo(catalogDatabase="parking-refined-zone",catalogTableName="parking_nas_live_manual_updates_with_pcns_box23")
parkingrefinedparking_nas_live_manual_updates_with_pcns_box23_node1718795102868.setFormat("glueparquet", compression="snappy")
parkingrefinedparking_nas_live_manual_updates_with_pcns_box23_node1718795102868.writeFrame(NASliveETApcnbox23listagg_node1718795096016)
job.commit()
