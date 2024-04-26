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
    table_name="cedar_parking_payments",
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
Parking_Cedar_Payments

This query summerises the Cedar Parking payments, into Parking and Cycle Hanger payments

14/09/2021 - create the query
15/09/2021 - Add code to identify the current and previous financial year
05/10/2021 - Remove the WHERE against Cedar_Parking_Payments because I am importing the 
             .csv data a month at a time
06/10/2021 - update for incorrect September date format import
08/11/2021 - update to collect dates BEFORE last Financial year
19/11/2021 - change code to tidy date formating
01/12/2021 - add where statement when collecting parking_payments 
               and set import_date to string
26/04/2024 - add further code to de-dupe the calendar data
****************************************************************************************************************/
WITH Cedar_Payments as (
SELECT 
   cc, subj,analysis, trandate,
   CASE
      When trandate like '%/%'Then CAST(substr(trandate, 7, 4)||'-'||substr(trandate, 4,2)||'-'||'01' as date)
      ELSE cast(concat(substr(Cast(trandate as varchar(10)),1, 7), '-01') as date) 
   END as PayMonthYear,  
   description, o_description, cast(financialvalue as decimal(10,2)) as financialvalue
FROM cedar_parking_payments
WHERE import_Date = (Select MAX(import_date) from cedar_parking_payments)),

Before_ICalendar as (
   SELECT
      CAST(CASE
         When date like '%/%'Then substr(date, 7, 4)||'-'||substr(date, 4,2)||'-'||substr(date, 1,2)
         ELSE substr(date, 1, 10)
      end as date) as date,  
      workingday,
      holiday,
      dow,
      fin_year,
      fin_year_startdate,
      fin_year_enddate
   FROM calendar),

/* 26/04/2024 - new code to de-dupe the calendar data */
ICalendar as (
    Select *,
        ROW_NUMBER() OVER ( PARTITION BY date ORDER BY  date DESC) row_num
    FROM Before_ICalendar),
    
Cedar_Summary as (
SELECT 
   PayMonthYear, CASE When Description != 'Cycle Hangar' Then 'Parking' Else 'Cycle Hangar' END as PaymentType,
   SUM(financialvalue) as TotalPayments
FROM Cedar_Payments as A
group by PayMonthYear,CASE When Description != 'Cycle Hangar' Then 'Parking' Else 'Cycle Hangar' END),

LatestYear as (
  SELECT MAX(fin_year) as LYear from Calendar)
  
SELECT A.*,
    /* Identify the Financial year, this, last, previous to last */
    CASE
       When cast(substr(cast(current_date as string), 6, 2) as int) = 4 Then 
          CASE
             When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-1 as varchar(4)) Then 'Current'
             When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-2 as varchar(4)) Then 'Previous'
             When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-3 as varchar(4)) Then 'PreviousPrevious' 
          END
      ELSE
         CASE
            When B.fin_year = (Select LYear from LatestYear)                                    Then 'Current'
            When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-1 as varchar(4)) Then 'Previous'
            When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-2 as varchar(4)) Then 'Before_Previous'
         Else 'NULL'
         END
    END as Year_Type,

    current_timestamp()            as ImportDateTime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    cast(Year(current_date) as string)    as import_year, 
    cast(month(current_date) as string)   as import_month, 
    cast(day(current_date) as string)     as import_day
    
FROM Cedar_Summary as A
LEFT JOIN ICalendar as B ON A.PayMonthYear = date and row_num = 1
order by A.PayMonthYear
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "cedar_parking_payments": AmazonS3_node1625732038443,
        "calendar": AmazonS3_node1631704526786,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Cedar_Payments/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Cedar_Payments",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
