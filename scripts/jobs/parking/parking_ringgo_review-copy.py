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

# Script generated for node Amazon S3
AmazonS3_node1648208237020 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="ringgo_daily",
    transformation_ctx="AmazonS3_node1648208237020",
)

# Script generated for node Amazon S3
AmazonS3_node1652190326034 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="pd_location_machines",
    transformation_ctx="AmazonS3_node1652190326034",
)

# Script generated for node Amazon S3
AmazonS3_node1658479409037 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1658479409037",
)

# Script generated for node Amazon S3
AmazonS3_node1655979270100 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="ringgo_session_forecast",
    transformation_ctx="AmazonS3_node1655979270100",
)

# Script generated for node Amazon S3
AmazonS3_node1655979050009 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="cash_collection",
    transformation_ctx="AmazonS3_node1655979050009",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*********************************************************************************
Parking_Ringgo_Review

This SQL totals the number of Ringgo transactions

22/03/2022 - Create Query
21/07/2022 - rewrite the query to display the data in Quarters
*********************************************************************************/
With Calendar_Data as (
   SELECT
      date as Calendar_date, workingday, dow, holiday,fin_year,
      CASE
         When cast(substr(date, 6,2) as int) = 1 Then 'Q4' -- Jan
         When cast(substr(date, 6,2) as int) = 2 Then 'Q4' -- Feb  
         When cast(substr(date, 6,2) as int) = 3 Then 'Q4' -- March
         When cast(substr(date, 6,2) as int) = 4 Then 'Q1' -- Apr    
         When cast(substr(date, 6,2) as int) = 5 Then 'Q1' -- May  
         When cast(substr(date, 6,2) as int) = 6 Then 'Q1' -- June  
         When cast(substr(date, 6,2) as int) = 7 Then 'Q2' -- Jul   
         When cast(substr(date, 6,2) as int) = 8 Then 'Q2' -- Aug 
         When cast(substr(date, 6,2) as int) = 9 Then 'Q2' -- Sept
         When cast(substr(date, 6,2) as int) = 10 Then 'Q3' -- Oct    
         When cast(substr(date, 6,2) as int) = 11 Then 'Q3' -- Nov 
         When cast(substr(date, 6,2) as int) = 12 Then 'Q3' -- Dec
         Else ''
      END as QTR,
      
      ROW_NUMBER() OVER ( PARTITION BY date ORDER BY  date, import_date DESC) row_num
   FROM calendar),

CalendarFormat as (
   SELECT
      CAST(CASE
         When Calendar_date like '%/%'Then substr(Calendar_date, 7, 4)||'-'||
                                           substr(Calendar_date, 4, 2)||'-'||substr(Calendar_date, 1, 2)
         ELSE substr(Calendar_date, 1, 10)
      END as date) as Format_date, fin_year, QTR
   FROM Calendar_Data
   WHERE row_num = 1),
   
Latest_Report_Year as (
   SELECT
      /**** Find the Latest Financial Year ***/
      CASE
         /** Q1 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 4 Then cast(cast(fin_year as int) - 1 as string)
         When cast(substr(cast(Format_date as string),6,2) as int) = 5 Then cast(cast(fin_year as int) - 1 as string)
         When cast(substr(cast(Format_date as string),6,2) as int) = 6 Then cast(cast(fin_year as int) - 1 as string)
         /** Q2 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 7 Then fin_year
         When cast(substr(cast(Format_date as string),6,2) as int) = 8 Then fin_year
         When cast(substr(cast(Format_date as string),6,2) as int) = 9 Then fin_year
         /** Q3 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 10 Then fin_year
         When cast(substr(cast(Format_date as string),6,2) as int) = 11 Then fin_year
         When cast(substr(cast(Format_date as string),6,2) as int) = 12 Then fin_year
         /** Q4 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 1 Then fin_year
         When cast(substr(cast(Format_date as string),6,2) as int) = 2 Then fin_year
         When cast(substr(cast(Format_date as string),6,2) as int) = 3 Then fin_year
      END as LatestReportYear,
      /**** Find the Latest Quarter ***/
      CASE
         /** Q1 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 4 Then 'Q4'
         When cast(substr(cast(Format_date as string),6,2) as int) = 5 Then 'Q4'
         When cast(substr(cast(Format_date as string),6,2) as int) = 6 Then 'Q4'
         /** Q2 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 7 Then 'Q1'
         When cast(substr(cast(Format_date as string),6,2) as int) = 8 Then 'Q1'
         When cast(substr(cast(Format_date as string),6,2) as int) = 9 Then 'Q1'
         /** Q3 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 10 Then 'Q2'
         When cast(substr(cast(Format_date as string),6,2) as int) = 11 Then 'Q2'
         When cast(substr(cast(Format_date as string),6,2) as int) = 12 Then 'Q2'
         /** Q4 **/
         When cast(substr(cast(Format_date as string),6,2) as int) = 1 Then 'Q3'
         When cast(substr(cast(Format_date as string),6,2) as int) = 2 Then 'Q3'
         When cast(substr(cast(Format_date as string),6,2) as int) = 3 Then 'Q3'
      END as LatestQTR,

    CASE
        When cast(substr(cast(Format_date as string),6,2) as int) = 4 Then 
                                cast(substr(cast(Format_date as string),1,5)||'03-01' as date)  
        When cast(substr(cast(Format_date as string),6,2) as int) = 5 Then 
                                cast(substr(cast(Format_date as string),1,5)||'03-01' as date)   
        When cast(substr(cast(Format_date as string),6,2) as int) = 6 Then 
                                cast(substr(cast(Format_date as string),1,5)||'03-01' as date)
        When cast(substr(cast(Format_date as string),6,2) as int) = 7 Then 
                                cast(substr(cast(Format_date as string),1,5)||'06-01' as date)  
        When cast(substr(cast(Format_date as string),6,2) as int) = 8 Then 
                                cast(substr(cast(Format_date as string),1,5)||'06-01' as date)  
        When cast(substr(cast(Format_date as string),6,2) as int) = 9 Then 
                                cast(substr(cast(Format_date as string),1,5)||'06-01' as date)  
        When cast(substr(cast(Format_date as string),6,2) as int) = 10 Then 
                                cast(substr(cast(Format_date as string),1,5)||'09-01' as date)  
        When cast(substr(cast(Format_date as string),6,2) as int) = 11 Then 
                                cast(substr(cast(Format_date as string),1,5)||'09-01' as date)   
        When cast(substr(cast(Format_date as string),6,2) as int) = 12 Then 
                                cast(substr(cast(Format_date as string),1,5)||'09-01' as date) 
        When cast(substr(cast(Format_date as string),6,2) as int) = 1 Then 
                                cast(substr(cast(Format_date as string),1,5)||'12-01' as date)  
        When cast(substr(cast(Format_date as string),6,2) as int) = 2 Then 
                                cast(substr(cast(Format_date as string),1,5)||'12-01' as date)   
        When cast(substr(cast(Format_date as string),6,2) as int) = 3 Then 
                                cast(substr(cast(Format_date as string),1,5) ||'12-01' as date)
    END as Adj_Date
From CalendarFormat
Where format_date = current_date),
/******************************************************************************************************************
obtain the Ringgo data
*******************************************************************************************************************/
Ringgo_2019 as (
    Select cast(substr(session_start, 1, 8)||'01' as date) as Start_Date,
        Sum(cast(duration_in_mins as int))          as TotalMins,        
        count(*)                                    as Session_Total,
        Sum(cast(parking_fee as decimal(10,2)))     as Total_Paid

    From ringgo_daily as A
    LEFT JOIN PD_Location_Machines as B ON 
                    A.parking_zone = B.ringgo_location_no
    Where cast(substr(session_start, 1, 10) as date) 
                    between cast('2019-04-01' as date) and cast('2020-03-31' as date)
    AND B.zone IN ('A', 'D','F','G','G2','H','K','L','N','P','Q','S','U','T')
    Group By cast(substr(session_start, 1, 8)||'01' as date)),

Cash_Collection_2019 as (
    Select SUM(cast(subtotal as decimal(10,2))) as TotalPaid
    From cash_collection as A
    LEFT JOIN PD_Location_Machines as B ON A.fullname = B.machine_id
    Where cast(collectiondate as date) between cast('2019-04-01' as date) 
    and cast('2020-03-31' as date) 
        AND B.zone IN ('A', 'D','F','G','G2','H','K','L','N','P','Q','S','U','T')),

Totals_2019 as (
    SELECT 
        SUM(Total_Paid)                                 as Ringgo_Total_2019, 
        (Select TotalPaid from Cash_Collection_2019)    as Cash_Collection_Total_2019,
        1-((SUM(Total_Paid) - (Select TotalPaid from Cash_Collection_2019))
                /SUM(Total_Paid)) as CC_Percentage,
        
        cast(SUM(Session_Total)+(SUM(Session_Total) * (1-((SUM(Total_Paid) - 
                (Select TotalPaid from Cash_Collection_2019))/SUM(Total_Paid)))) as int) as Session_2019_TOTAL,

        (cast(SUM(Session_Total)+(SUM(Session_Total) * (1-((SUM(Total_Paid) - 
            (Select TotalPaid from Cash_Collection_2019))/SUM(Total_Paid)))) as int)/12) as Monthly_Session_2019_TOTAL
    FROM Ringgo_2019),
/******************************************************************************************************************
Monthly totals 2021 on 
*******************************************************************************************************************/
Ringgo_Forecast_Totals as (
    Select 
    CAST(substr(start_date, 7, 4)||'-'||substr(start_date, 4, 2)||'-'||
            substr(start_date, 1, 2) as date) as Month,
    CAST(session_total as int) + cast(cast(session_total as int) * 0.04 as int) 
            as Forecast_Totals
From ringgo_session_forecast),
/******************************************************************************************************************
Create the output data
*******************************************************************************************************************/
FULL_Data as (
SELECT 
    A.Month, 
    CASE
        When QTR is not NULL Then QTR
        ELSE
        CASE
            When cast(substr(cast(A.Month as string), 6,2) as int) = 1 Then 'Q4' -- Jan
            When cast(substr(cast(A.Month as string), 6,2) as int) = 2 Then 'Q4' -- Feb  
            When cast(substr(cast(A.Month as string), 6,2) as int) = 3 Then 'Q4' -- March
            When cast(substr(cast(A.Month as string), 6,2) as int) = 4 Then 'Q1' -- Apr    
            When cast(substr(cast(A.Month as string), 6,2) as int) = 5 Then 'Q1' -- May  
            When cast(substr(cast(A.Month as string), 6,2) as int) = 6 Then 'Q1' -- June  
            When cast(substr(cast(A.Month as string), 6,2) as int) = 7 Then 'Q2' -- Jul   
            When cast(substr(cast(A.Month as string), 6,2) as int) = 8 Then 'Q2' -- Aug 
            When cast(substr(cast(A.Month as string), 6,2) as int) = 9 Then 'Q2' -- Sept
            When cast(substr(cast(A.Month as string), 6,2) as int) = 10 Then 'Q3' -- Oct    
            When cast(substr(cast(A.Month as string), 6,2) as int) = 11 Then 'Q3' -- Nov 
            When cast(substr(cast(A.Month as string), 6,2) as int) = 12 Then 'Q3' -- Dec
            Else ''
        END
    END as QTR,
    CASE
        When cast(A.Month as date) between cast('2021-04-01' as date) 
                                                    and cast('2022-03-01' as date) Then 2021
        When cast(A.Month as date) between cast('2022-04-01' as date) 
                                                    and cast('2023-03-01' as date) Then 2022
        When cast(A.Month as date) between cast('2023-04-01' as date) 
                                                    and cast('2024-03-01' as date) Then 2023
        When cast(A.Month as date) between cast('2024-04-01' as date) 
                                                    and cast('2025-03-01' as date) Then 2024
        When cast(A.Month as date) between cast('2025-04-01' as date) 
                                                    and cast('2026-03-01' as date) Then 2025
    END as fin_year,
    
    A.Forecast_Totals, 
    (Select Monthly_Session_2019_TOTAL FROM Totals_2019) as Baseline_2019,
    
    (Select cast(LatestReportYear as int) From Latest_Report_Year)  as Latest_Year,
    (Select LatestQTR From Latest_Report_Year)                      as Latest_QTR,
    (Select cast(Adj_Date as date) From Latest_Report_Year)         as Latest_Date,    
    
    /** Catch the duplicate records **/
    ROW_NUMBER() OVER ( PARTITION BY A.Month,QTR,fin_year ORDER BY  A.Month,QTR,fin_year DESC) RN

FROM Ringgo_Forecast_Totals as A
LEFT JOIN Calendar_Data as B ON A.Month = cast(B.Calendar_date as date)
WHERE A.Month != cast('2025-03-31' as date)),

Final as (
SELECT 
    Month, QTR, fin_year, Forecast_Totals, Baseline_2019,
    CASE
        When Month <= Latest_Date Then 1
        ELSE 0
    End as ReportFlag
FROM FULL_Data
WHERE RN = 1)
/**** Final summerised output ******/
SELECT 
    fin_year, QTR,
    SUM(Forecast_Totals)    as Session_Forecast,
    SUM(Baseline_2019)      as Baseline_Total,
    SUM(CASE
            When ReportFlag = 1 Then Forecast_Totals
            Else 0
        END) As Actual_Session,
        
    (cast(SUM(Forecast_Totals) as decimal(10,4)) - SUM(Baseline_2019))
   /
    ((cast(SUM(Forecast_Totals) as decimal(10,4)) + SUM(Baseline_2019))/2) as Percentage_Diff, 
        
    current_timestamp()                            as ImportDateTime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    cast(Year(current_date) as string)    as import_year, 
    cast(month(current_date) as string)   as import_month, 
    cast(day(current_date) as string)     as import_day
FROM Final
GROUP BY fin_year, QTR
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "PD_Location_Machines": AmazonS3_node1652190326034,
        "ringgo_daily": AmazonS3_node1648208237020,
        "ringgo_session_forecast": AmazonS3_node1655979270100,
        "cash_collection": AmazonS3_node1655979050009,
        "calendar": AmazonS3_node1658479409037,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Ringgo_Review/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Ringgo_Review",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
