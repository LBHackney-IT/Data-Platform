import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import create_pushdown_predicate, get_glue_env_var

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
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_cedar_payments",
    transformation_ctx="AmazonS3_node1625732038443",
    # teporarily removed while table partitions are fixed
    # push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node Amazon S3
AmazonS3_node1631887639199 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1631887639199",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*************************************************************************************************************************
Parking_Cedar_Total_Monthly_Summary

The SQL as been created to create monthly values & % difference between last financial year and this financial year

17/09/2021 - Create SQL
06/10/2021 - change the calculation of year -on - year %
07/10/2021 - change the calc of % back...there seems to be a problem
18/11/2021 - add code to format the calendar date and to identify payments beore last year
02/12/2021 - change import_date to string
19/04/2022 - change calculation of the current/past/etc Fin Year
29/04/2024 add additional de-dupe for the calendar year
*************************************************************************************************************************/
/*** Format the date because Calendar data imported with different date formats!!! ***/
With BeforeCalendarFormat as (
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

/* 29/04/2024 - new code to de-dupe the calendar data */
CalendarFormat as (
    Select *,
        ROW_NUMBER() OVER ( PARTITION BY date ORDER BY date DESC) R1
    FROM BeforeCalendarFormat),

LatestYear as (
SELECT MAX(fin_year) as LYear from CalendarFormat
Where date <= current_date),


Full_Fin_Data as (
SELECT
    cast(paymonthyear as date)              as Pay_Year,
    cast(-(totalpayments) as decimal(10,2)) as Total_Paid,
    CASE
        When date_format(paymonthyear, "M") = '1'  Then 'Jan'
        When date_format(paymonthyear, "M") = '2'  Then 'Feb'
        When date_format(paymonthyear, "M") = '3'  Then 'Mar'
        When date_format(paymonthyear, "M") = '4'  Then 'Apr'
        When date_format(paymonthyear, "M") = '5'  Then 'May'
        When date_format(paymonthyear, "M") = '6'  Then 'Jun'
        When date_format(paymonthyear, "M") = '7'  Then 'Jul'
        When date_format(paymonthyear, "M") = '8'  Then 'Aug'
        When date_format(paymonthyear, "M") = '9'  Then 'Sep'
        When date_format(paymonthyear, "M") = '10' Then 'Oct'
        When date_format(paymonthyear, "M") = '11' Then 'Nov'
        When date_format(paymonthyear, "M") = '12' Then 'Dec'
    END as Pay_Month,

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
            When B.fin_year = cast((Select cast(LYear as int) from LatestYear)-2 as varchar(4)) Then 'PreviousPrevious'
         Else 'NULL'
         END
    END as Year_Type

FROM parking_cedar_payments as A
LEFT JOIN CalendarFormat as B ON A.PayMonthYear = Cast(Cast(B.date as varchar(10)) as date) and R1 = 1
WHERE A.import_Date = (Select MAX(import_date) from parking_cedar_payments) and
paymenttype = 'Parking'),

/***********************************************************************************************************************************/
/*** Total the months payments ***/
Curent_ToDate as (
SELECT Pay_Month as Month, A.Pay_Year,
   CASE
      When A.Pay_Month = 'Apr' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month = 'Apr'
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'May' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Jun' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Jul' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Aug' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Sep' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Oct' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Nov' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Dec' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec')
                                AND Year_Type = 'Current')
       When A.Pay_Month = 'Jan' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan')
                AND Year_Type = 'Current')
       When A.Pay_Month = 'Feb' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb')
                AND Year_Type = 'Current')
       When A.Pay_Month = 'Mar' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar')
                AND Year_Type = 'Current')

   END as TotalToDate, A.Total_Paid
FROM Full_Fin_Data as A
WHERE Year_Type = 'Current'
ORDER BY A.Pay_Year),

/*** Previous Month(s) ***/
Previous_ToDate as (
SELECT Pay_Month as Month, A.Pay_Year,
   CASE
      When A.Pay_Month = 'Apr' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month = 'Apr'
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'May' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Jun' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Jul' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Aug' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Sep' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Oct' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Nov' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Dec' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec')
                                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Jan' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan')
                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Feb' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb')
                AND Year_Type = 'Previous')
       When A.Pay_Month = 'Mar' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar')
                AND Year_Type = 'Previous')

   END as TotalToDate, A.Total_Paid
FROM Full_Fin_Data as A
WHERE Year_Type = 'Previous'
ORDER BY A.Pay_Year),

/*** Previous- previous Month(s) ***/
PreviousPrevious_ToDate as (
SELECT Pay_Month as Month, A.Pay_Year,
   CASE
      When A.Pay_Month = 'Apr' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month = 'Apr'
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'May' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Jun' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Jul' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Aug' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Sep' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Oct' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Nov' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Dec' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec')
                                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Jan' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan')
                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Feb' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb')
                AND Year_Type = 'PreviousPrevious')
       When A.Pay_Month = 'Mar' Then
                        (Select SUM(Z.Total_Paid) From Full_Fin_Data as Z
                Where Z.Pay_Month IN ('Apr', 'May', 'Jun','Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar')
                AND Year_Type = 'PreviousPrevious')

   END as TotalToDate, A.Total_Paid
FROM Full_Fin_Data as A
WHERE Year_Type = 'PreviousPrevious'
ORDER BY A.Pay_Year),

DeDupe_Data as (
SELECT
    A.Month,
    A.TotalToDate  as Current_Monthly_Total,
    B.TotalToDate  as Previous_Monthly_Total,
    C.TotalToDate  as PreviousPrevious_Monthly_Total,
    A.Pay_Year,

   /** try and trap duplicates **/
   ROW_NUMBER() OVER ( PARTITION BY A.Month, A.TotalToDate, B.TotalToDate,C.TotalToDate, A.Pay_Year
        ORDER BY A.Month, A.TotalToDate, B.TotalToDate,C.TotalToDate, A.Pay_Year DESC) row_num
FROM Curent_ToDate as A
LEFT JOIN Previous_ToDate as B ON A.Month = B.Month
LEFT JOIN PreviousPrevious_ToDate as C ON A.Month = C.Month)

/*** Ouput Summary data & Apply a percentage diff ***/
SELECT
    Month,
    Current_Monthly_Total,
    Previous_Monthly_Total,
    PreviousPrevious_Monthly_Total,

    CAST((Previous_Monthly_Total/Current_Monthly_Total)*100  as decimal(10,2)) as PercentageDiff,

    Pay_Year,
    current_timestamp() as ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date

FROM DeDupe_Data
WHERE row_num = 1
ORDER BY Pay_Year
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_cedar_payments": AmazonS3_node1625732038443,
        "calendar": AmazonS3_node1631887639199,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Cedar_Total_Monthly_Summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Cedar_Total_Monthly_Summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
