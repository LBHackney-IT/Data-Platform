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
AmazonS3_node1625732038443 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="cedar_backing_data",
    transformation_ctx="AmazonS3_node1625732038443",
)

# Script generated for node Amazon S3
AmazonS3_node1631704526786 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1631704526786",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/**************************************************************************************************************
Parking_Cedar_Backing_Data_Summary

This query summerises the Cedar backing data 

08/11/2021 - create the query
08/05/2024 - update for different backing data date format and calendar format
****************************************************************************************************************/
/*** Collect & Format the backing data ***/
WITH CedarBackingData as (
    SELECT
        CAST(CASE 
            When trandate like '%/%'Then
                substr(trandate, 7, 4)||'-'||substr(trandate, 4, 2)||'-'||'01'
            ELSE 
                substr(trandate, 1, 8)||'01'
        END as date) as IssueMonthYear,
       reftype, sub_reftype, cast(REPLACE(REPLACE(financialvalue, '£',''),',','') as decimal(15,2)) as financialvalue
    FROM cedar_backing_data
    Where import_Date = (Select MAX(import_date) from cedar_backing_data)),

Before_ICalendar as (
    SELECT
       CAST(
            CASE
                When date like '%/%'Then
                    substr(date, 7, 4)||'-'||substr(date, 4, 2)||'-'||substr(date, 1, 2)
                ELSE date
       END as date) as Date,
       dow,
       fin_year, fin_year_startdate, fin_year_enddate
    FROM calendar),
    
/** 08/05/2024 - Add de-dupe of calendar **/
ICalendar as (
    Select *,
        ROW_NUMBER() OVER ( PARTITION BY date ORDER BY date DESC) R1
    FROM Before_ICalendar),
    
LatestYear as (
  SELECT MAX(fin_year) as LYear from Calendar),

/*** Summerise the data ***/
Payment_Summary as (
    SELECT
       IssueMonthYear, reftype, sub_reftype, SUM(financialvalue) as Total_Payments
    FROM CedarBackingData
    GROUP BY IssueMonthYear, reftype, sub_reftype
    ORDER BY IssueMonthYear, reftype, sub_reftype)

/*** OUTPUT THE DATA ***/
SELECT A.*,
    /* Identify the Financial year, this, last, previous to last */
    CASE
       When cast(substr(cast(current_date as string), 6, 2) as int) = 4 Then 
          CASE
             When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-1 as varchar(4)) Then 'Current'
             When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-2 as varchar(4)) Then 'Previous'
             When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-3 as varchar(4)) Then 'Before_Previous' 
          END
      ELSE
         CASE
            When B.fin_year = (Select LYear from LatestYear)                                    Then 'Current'
            When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-1 as varchar(4)) Then 'Previous'
            When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-2 as varchar(4)) Then 'Before_Previous'
         Else ''
         END
    END as Year_Type,

    current_timestamp() as ImportDateTime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    Year(current_date)    as import_year, 
    month(current_date)   as import_month, 
    day(current_date)     as import_day    

FROM Payment_Summary as A
LEFT JOIN ICalendar as B ON A.IssueMonthYear = date AND R1 = 1
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "cedar_backing_data": AmazonS3_node1625732038443,
        "calendar": AmazonS3_node1631704526786,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Cedar_Backing_Data_Summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Cedar_Backing_Data_Summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
