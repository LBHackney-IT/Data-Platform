import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, create_pushdown_predicate
environment = get_glue_env_var("environment")


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
spark.conf.set("spark.sql.broadcastTimeout", 7200)

# Script generated for node S3 - liberator_refined - parking_permit_denormalised_gds_street_llpg
S3liberator_refinedparking_permit_denormalised_gds_street_llpg_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_permit_denormalised_gds_street_llpg",
    transformation_ctx="S3liberator_refinedparking_permit_denormalised_gds_street_llpg_node1",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*Permit changes comparison - compare changes in permits from the parking_permit_denormalised_gds_street_llpg table to be used in Google Data Studio
Compares latest import to previous import in table
01/03/2022 - Created glue job

*/

with previous as (
SELECT distinct concat(permit_reference, cast(start_date as string)) as p_unique ,parking_permit_denormalised_gds_street_llpg.import_date as p_import_date ,vrm as p_latest_vrm ,permit_reference as p_permit_reference	,application_date as p_application_date	,blue_badge_number as p_blue_badge_number	,blue_badge_expiry as p_blue_badge_expiry	,start_date as p_start_date	,end_date as p_end_date	,permit_type as p_permit_type	,cpz as p_cpz	,cpz_name as p_cpz_name	,latest_permit_status as p_latest_permit_status	,make as p_make	,model as p_model	,fuel as p_fuel	,engine_capactiy as p_engine_capactiy	,co2_emission as p_co2_emission	,foreign as p_foreign	,lpg_conversion as p_lpg_conversion	,vrm_record_created as p_vrm_record_created	,fin_year_flag as p_fin_year_flag	,fin_year as p_fin_year	,sr_usrn as p_USRN ,live_permit_flag as p_live_permit_flag 
    FROM parking_permit_denormalised_gds_street_llpg where parking_permit_denormalised_gds_street_llpg.import_date = (SELECT parking_permit_denormalised_gds_street_llpg.import_date 
  FROM parking_permit_denormalised_gds_street_llpg
    WHERE parking_permit_denormalised_gds_street_llpg.import_date NOT IN (SELECT MAX(parking_permit_denormalised_gds_street_llpg.import_date) FROM parking_permit_denormalised_gds_street_llpg ) 
ORDER BY parking_permit_denormalised_gds_street_llpg.import_date DESC LIMIT 1) 
)
, current as (
SELECT distinct concat(permit_reference, cast(start_date as string)) as c_unique ,parking_permit_denormalised_gds_street_llpg.import_date as c_import_date ,vrm as c_latest_vrm ,permit_reference as c_permit_reference	,application_date as c_application_date	,blue_badge_number as c_blue_badge_number	,blue_badge_expiry as c_blue_badge_expiry	,start_date as c_start_date	,end_date as c_end_date	,permit_type as c_permit_type	,cpz as c_cpz	,cpz_name as c_cpz_name	,latest_permit_status as c_latest_permit_status	,make as c_make	,model as c_model	,fuel as c_fuel	,engine_capactiy as c_engine_capactiy	,co2_emission as c_co2_emission	,foreign as c_foreign	,lpg_conversion as c_lpg_conversion	,vrm_record_created as c_vrm_record_created	,fin_year_flag as c_fin_year_flag	,fin_year as c_fin_year	,sr_usrn as c_USRN ,live_permit_flag as c_live_permit_flag FROM parking_permit_denormalised_gds_street_llpg where parking_permit_denormalised_gds_street_llpg.import_date = (SELECT max(parking_permit_denormalised_gds_street_llpg.import_date) FROM parking_permit_denormalised_gds_street_llpg)
)
, permit_num as (
SELECT permit_reference as pn_permit_reference ,count(*) as num_permit ,min(application_date) as min_application_date ,max(application_date) as max_application_date ,min(start_date) as min_start_date ,max(start_date) as max_start_date	,min(end_date) as min_end_date ,max(end_date) as max_end_date FROM parking_permit_denormalised_gds_street_llpg where import_date = (SELECT max(import_date) FROM parking_permit_denormalised_gds_street_llpg)  group by permit_reference order by permit_reference 
)
select 
case when c_latest_permit_status = p_latest_permit_status then 0 else 1 end as diff_permit_status 
,case when previous.p_unique is null then 1 else 0 end as new_permit_start 
,case when previous.p_unique is null and permit_num.num_permit < 2 then 1 else 0 end as new_permit 
,case when c_latest_vrm =  p_latest_vrm then 0 else 1 end as diff_vrm
,case when p_start_date = c_start_date then 0 else 1 end as diff_start_date	
,case when p_end_date = c_end_date then 0 else 1 end as diff_end_date 
,case when p_vrm_record_created = c_vrm_record_created then 0 else 1 end as diff_vrm_rec_create 
,case when p_live_permit_flag = c_live_permit_flag then 0 else 1 end as diff_live_permit_flag 
,case when c_latest_permit_status in('Approved','Renewed','Created','ORDER_APPROVED','PENDING_VRM_CHANGE','RENEW_EVID','PENDING_ADDR_CHANGE') and c_live_permit_flag = 1 then 1 else 0 end as live_flag 

,case when ((case when c_latest_permit_status = p_latest_permit_status then 0 else 1 end)=1 or (case when c_latest_vrm =  p_latest_vrm then 0 else 1 end)=1 or (case when p_start_date = c_start_date then 0 else 1 end)=1 or (case when p_end_date = c_end_date then 0 else 1 end)=1 or (case when p_vrm_record_created = c_vrm_record_created then 0 else 1 end)=1 or (case when p_live_permit_flag = c_live_permit_flag then 0 else 1 end)=1) and c_latest_permit_status in('Approved','Renewed','Created','ORDER_APPROVED','PENDING_VRM_CHANGE','RENEW_EVID','PENDING_ADDR_CHANGE') and c_live_permit_flag = 1 
then 1 else 0 end as live_permit_change
,case when (case when c_latest_permit_status = p_latest_permit_status then 0 else 1 end)=1 or (case when c_latest_vrm =  p_latest_vrm then 0 else 1 end)=1 or (case when p_start_date = c_start_date then 0 else 1 end)=1 or (case when p_end_date = c_end_date then 0 else 1 end)=1 or (case when p_vrm_record_created = c_vrm_record_created then 0 else 1 end)=1 or (case when p_live_permit_flag = c_live_permit_flag then 0 else 1 end)=1 
then 1 else 0 end as permit_change
,*
    /*** Control Dates ***/       
    ,substr(Cast(current_date as varchar(10)),1, 4) as import_year,
    substr(Cast(current_date as varchar(10)),6, 2) as import_month,
    substr(Cast(current_date as varchar(10)),9, 4) as import_day,
    Cast(current_date as varchar(10))              as import_date
    
from current
left join previous on current.c_unique = previous.p_unique
left join permit_num on current.c_permit_reference = permit_num.pn_permit_reference
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_permit_denormalised_gds_street_llpg": S3liberator_refinedparking_permit_denormalised_gds_street_llpg_node1
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_gds_permit_change_comparison/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_gds_permit_change_comparison",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
