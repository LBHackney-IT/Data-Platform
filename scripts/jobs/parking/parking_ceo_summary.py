import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var
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

# Script generated for node Amazon S3
AmazonS3_node1628173244776 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_ceo",
    transformation_ctx="AmazonS3_node1628173244776",
)

# Script generated for node Amazon S3
AmazonS3_node1632912445458 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_cb",
    transformation_ctx="AmazonS3_node1632912445458",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/***************************************************************************************************************************
Parking_CEO_Summary

This SQL summerises the CEO On-Street logs 

28/09/2021 - create SQL
***************************************************************************************************************************/
WITH CEO_Summary as (
select 
   officer_shoulder_no, cast(substr(officer_patrolling_date, 1, 10) as date) CEO_Protrol_Date, 
   Min(cast(officer_patrolling_date as timestamp)) CEO_Start_DateTime,
   Max(cast(officer_patrolling_date as timestamp)) CEO_End_DateTime,
   SUM(CASE When ticket_number like 'QZ%' Then 1 else 0 end) No_PCNs_Issued,
   SUM(CASE When vrm = 'OBSERVED' Then 1 else 0 END) No_of_Observations,
   SUM(CASE When officer_street_name = 'CEO on break' Then 1 Else 0 END) CEO_No_of_Breaks,
   SUM(CASE When officer_street_name = 'CEO on break' Then 
   unix_timestamp(break_end)-unix_timestamp(break_start) else 0 end) as Total_Break
  
from liberator_pcn_ceo as A
WHERE officer_street_name != 'null'
Group By officer_shoulder_no, cast(substr(officer_patrolling_date, 1, 10) as date)),

PCN_CB as (
Select ceo_shoulder_no,activity_date,
   beat, shift, beat_start_point, shift_lunch, method_of_travel,
   travel_time,
   shift_start_time, 
   shift_end_time
FROM liberator_pcn_cb
WHERE import_Date = (Select MAX(import_date) from liberator_pcn_cb)),

StreetList as (
select officer_shoulder_no, cast(substr(officer_patrolling_date, 1, 10) as date) CEO_Protrol_Date, officer_street_name as Street
from liberator_pcn_ceo as A
WHERE officer_street_name != 'null'
Group By officer_shoulder_no, cast(substr(officer_patrolling_date, 1, 10) as date), officer_street_name),

StreetSum as (
Select officer_shoulder_no, CEO_Protrol_Date, count(*) as No_of_Streets_Visited
From StreetList
Group By officer_shoulder_no, CEO_Protrol_Date)

SELECT 
   A.*,
   unix_timestamp(CEO_End_DateTime)-unix_timestamp(CEO_Start_DateTime) as TimeOnStreet_Secs,
   
   SUBSTRING(cast(Total_Break as timestamp), 11) as Total_Break_HrMin,
   SUBSTRING(cast(unix_timestamp(CEO_End_DateTime)-unix_timestamp(CEO_Start_DateTime) as timestamp), 11) as TimeOnStreet_HourMin,
   
   No_of_Streets_Visited,

   /*** Beat information ***/
   C.beat, C.shift, C.beat_start_point, C.shift_lunch, C.method_of_travel, 
   LTRIM(REPLACE(REPLACE(C.travel_time, 'Minutes',''),'mins','')) as travel_time,
   C.shift_start_time, 
   C.shift_end_time,
   
   current_timestamp as ImportDateTime,
   
    replace(cast(current_date() as string),'-','') as import_date,
    
    -- Add the Import date
    cast(Year(current_date) as string)  as import_year, 
    cast(month(current_date) as string) as import_month, 
    cast(day(current_date) as string)   as import_day    
   
FROM CEO_Summary as A
LEFT JOIN StreetSum as B ON A.officer_shoulder_no = B.officer_shoulder_no AND A.CEO_Protrol_Date = B.CEO_Protrol_Date
LEFT JOIN PCN_CB as C ON A.officer_shoulder_no = C.ceo_shoulder_no AND A.CEO_Protrol_Date = C.activity_date
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_ceo": AmazonS3_node1628173244776,
        "liberator_pcn_cb": AmazonS3_node1632912445458,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_CEO_Summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_CEO_Summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
