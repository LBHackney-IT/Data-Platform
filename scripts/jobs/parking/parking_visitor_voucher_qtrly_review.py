import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    get_glue_env_var,
    get_latest_partitions,
)


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
# add variable
environment = get_glue_env_var("environment")

# Script generated for node Amazon S3
AmazonS3_node1648207907397 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1648207907397",
)

# Script generated for node Amazon S3
AmazonS3_node1648208237020 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_voucher_de_normalised",
    transformation_ctx="AmazonS3_node1648208237020",
)

# Script generated for node Amazon S3
AmazonS3_node1652190326034 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="visitor_voucher_forecast",
    transformation_ctx="AmazonS3_node1652190326034",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*********************************************************************************
Parking_Visitor_Voucher_Review

This SQL totals the number of Visitor Voucher books (for Estate, 1 Day & 2 Hour Vouchers)
by Voucher Type and Quarter

22/03/2022 - Create Query
10/05/2022 - rewrite query to meet Michaels requirements
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
      END as LatestQTR
   From CalendarFormat
   Where format_date = current_date),
/********************************************************************************************
Obtain the Voucher forecast figures
********************************************************************************************/
 Voucher_Forecast as (
    Select monthyear, one_day, two_hour, estate,
      CASE
         When cast(substr(monthyear, 4,2) as int) = 1 Then 'Q4' -- Jan
         When cast(substr(monthyear, 4,2) as int) = 2 Then 'Q4' -- Feb
         When cast(substr(monthyear, 4,2) as int) = 3 Then 'Q4' -- March
         When cast(substr(monthyear, 4,2) as int) = 4 Then 'Q1' -- Apr
         When cast(substr(monthyear, 4,2) as int) = 5 Then 'Q1' -- May
         When cast(substr(monthyear, 4,2) as int) = 6 Then 'Q1' -- June
         When cast(substr(monthyear, 4,2) as int) = 7 Then 'Q2' -- Jul
         When cast(substr(monthyear, 4,2) as int) = 8 Then 'Q2' -- Aug
         When cast(substr(monthyear, 4,2) as int) = 9 Then 'Q2' -- Sept
         When cast(substr(monthyear, 4,2) as int) = 10 Then 'Q3' -- Oct
         When cast(substr(monthyear, 4,2) as int) = 11 Then 'Q3' -- Nov
         When cast(substr(monthyear, 4,2) as int) = 12 Then 'Q3' -- Dec
         Else ''
      END as QTR,
      CASE
         When cast(substr(monthyear, 4,2) as int) = 1 Then cast(cast(substr(monthyear, 7,4) as int)-1 as string)--Jan
         When cast(substr(monthyear, 4,2) as int) = 2 Then cast(cast(substr(monthyear, 7,4) as int)-1 as string)--Feb
         When cast(substr(monthyear, 4,2) as int) = 3 Then cast(cast(substr(monthyear, 7,4) as int)-1 as string)--Mar
         When cast(substr(monthyear, 4,2) as int) = 4 Then substr(monthyear, 7,4) -- Apr
         When cast(substr(monthyear, 4,2) as int) = 5 Then substr(monthyear, 7,4) -- May
         When cast(substr(monthyear, 4,2) as int) = 6 Then substr(monthyear, 7,4) -- June
         When cast(substr(monthyear, 4,2) as int) = 7 Then substr(monthyear, 7,4) -- Jul
         When cast(substr(monthyear, 4,2) as int) = 8 Then substr(monthyear, 7,4) -- Aug
         When cast(substr(monthyear, 4,2) as int) = 9 Then substr(monthyear, 7,4) -- Sept
         When cast(substr(monthyear, 4,2) as int) = 10 Then substr(monthyear, 7,4) -- Oct
         When cast(substr(monthyear, 4,2) as int) = 11 Then substr(monthyear, 7,4) -- Nov
         When cast(substr(monthyear, 4,2) as int) = 12 Then substr(monthyear, 7,4) -- Dec
         Else ''
      END as FinYear
    From visitor_voucher_forecast),
/********************************************************************************************
Obtain the Voucher de-normalised data. Format the Start and End number, remove rubbish
********************************************************************************************/
Vouchers as (
   SELECT voucher_ref, street, permit_type, cpz, quantity, e_voucher,
   /** Format the application Date **/
   CAST(CASE
           When application_date like '%/%'Then substr(application_date, 7, 4)||'-'||
                                           substr(application_date, 4, 2)||'-'||substr(application_date, 1, 2)
        ELSE substr(application_date, 1, 10)
    END as date) as application_date, Status, fin_year, QTR,

    CASE
       When Permit_Type = 'Estate Visitor Vouchers' Then cast(quantity as decimal) * 10
       When Permit_Type = '1 day visitors vouchers' Then cast(quantity as decimal) * 5
       When Permit_Type = '2 hour visitors vouchers' Then cast(quantity as decimal) * 20
       Else 0
    END as NoOFBooks

   from parking_voucher_de_normalised as A
   LEFT JOIN CalendarFormat as B ON cast(substr(A.application_date, 1, 10) as date) = B.Format_date
   Where Import_Date = (Select MAX(Import_Date) from parking_voucher_de_normalised)
   AND Permit_type IN ('Estate Visitor Vouchers','2 hour visitors vouchers','1 day visitors vouchers')
   AND cast(substr(application_date, 1, 10) as date) >= cast('2019-04-01' as date)
   AND Status != 'Rejected'),
/********************************************************************************************
Continue to format the data, obtain the no of Vouchers - 2019 data
********************************************************************************************/
Voucher_Tidy_2019 as (
   SELECT voucher_ref, permit_type,quantity, cpz, NoOFBooks, QTR
   from Vouchers
   WHERE Fin_Year = '2019'),
/********************************************************************************************
Summerise the 2019 data
********************************************************************************************/
Voucher_Baseline_2019 as (
   SELECT permit_type, SUM(NoOFBooks) as TotalNo, SUM(NoOFBooks)/4 as QTRTotal
   From Voucher_Tidy_2019
   WHERE Permit_Type = 'Estate Visitor Vouchers' OR cpz IN ('A', 'D','F','G','G2','H','K','L','N','P','Q','S','U','T')
   GROUP BY permit_type),
/********************************************************************************************
Continue to format the data, obtain the no of Vouchers - Last FULL FY Year
********************************************************************************************/
Voucher_Tidy_Latest as (
   SELECT voucher_ref, permit_type,quantity, cpz, application_date,NoOFBooks, QTR, fin_year
   from Vouchers
   WHERE Fin_Year = (Select LatestReportYear from Latest_Report_Year)),

Voucher_Baseline_Latest as (
   SELECT permit_type,
   QTR, fin_year,
   SUM(NoOFBooks) as TotalNo

   From Voucher_Tidy_Latest
   WHERE Permit_Type = 'Estate Visitor Vouchers' OR cpz IN ('A', 'D','F','G','G2','H','K','L','N','P','Q','S','U','T')
   GROUP BY permit_type, QTR, fin_year),
/********************************************************************************************
Continue to format the data, obtain & Qtrly total the forecast figures
********************************************************************************************/
Forecast_Qtrly as (
    Select
        FinYear, QTR, SUM(one_day) as One_Day,
        SUM(two_hour) as two_hour,
        SUM(estate) as estate
    From Voucher_Forecast
    Group By FinYear, QTR),

/*** Split for forecats data into each Permit Type ***/
Format_Forecast as (
    Select
        FinYear, QTR,
        '1 day visitors vouchers' as Permit_Type,
        One_Day as ForecastTotal , QtrTotal as Baseline_Qtr
    From Forecast_Qtrly as A
    inner join Voucher_Baseline_2019 as B ON '1 day visitors vouchers' = B.permit_type
    UNION ALL
    Select
        FinYear, QTR,
        '2 hour visitors vouchers' as Permit_Type,
        two_hour as ForecastTotal, QtrTotal as Baseline_Qtr
    From Forecast_Qtrly
    inner join Voucher_Baseline_2019 as B ON '2 hour visitors vouchers' = B.permit_type
    UNION ALL
    Select
        FinYear, QTR,
        'Estate Visitor Vouchers' as Permit_Type,
        estate as ForecastTotal, QtrTotal as Baseline_Qtr
    From Forecast_Qtrly
    inner join Voucher_Baseline_2019 as B ON 'Estate Visitor Vouchers' = B.permit_type
    UNION ALL
    Select
        '2019' as fin_year,
        'Q0'   as QTR,
        permit_type,
        QtrTotal, 0
    From Voucher_Baseline_2019)
/********************************************************************************************
Continue to format the data for printing
********************************************************************************************/
SELECT
    A.finyear, A.qtr, A.Permit_Type,
    Case
        When B.TotalNo is not NULL Then B.TotalNo
        When A.finyear = '2019'    Then ForecastTotal
    Else 0 End as TotalNo,
    Case
        When A.finyear = '2019' Then 0
        Else ForecastTotal
    End as ForecastTotal, Baseline_Qtr,

    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date
FROM Format_Forecast as A
LEFT JOIN Voucher_Baseline_Latest as B ON A.finyear = B.fin_year AND A.qtr = B.QTR AND A.Permit_Type = B.permit_type
Order by A.Permit_Type, A.finyear, A.qtr

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "calendar": AmazonS3_node1648207907397,
        "parking_voucher_de_normalised": AmazonS3_node1648208237020,
        "visitor_voucher_forecast": AmazonS3_node1652190326034,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Visitor_Voucher_Qtrly_Review/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Visitor_Voucher_Qtrly_Review",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
