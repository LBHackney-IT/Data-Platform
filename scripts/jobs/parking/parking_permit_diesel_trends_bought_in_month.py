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

environment = get_glue_env_var("environment")

# Script generated for node Amazon S3
AmazonS3_node1658997944648 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1658997944648",
)

# Script generated for node Amazon S3
AmazonS3_node1658998139048 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_permit_denormalised_data",
    transformation_ctx="AmazonS3_node1658998139048",
)

# Script generated for node Amazon S3
AmazonS3_node1658998021932 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_vrm_update",
    transformation_ctx="AmazonS3_node1658998021932",
    additional_options={"mergeSchema": "true"},
)

# Script generated for node SQL
SqlQuery14 = """
/************************************************************************
Parking_Permit_diesel_Tends_Bought_in_Month

The SQL builds the Permit diesel trends based upon the application date

26/07/2022 - Create SQL
*************************************************************************/
/*** Create the Calendar formatted data ***/
With Calendar_Data as (
   SELECT
      date as Calendar_date, workingday, dow, holiday,fin_year,
      cast(substr(cast(date as string),1, 8)||'01' as date) as MonthStartDate,
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
         When cast(substr(cast(Format_date as string),6,2) as int) = 4 Then
                                        cast(cast(fin_year as int) - 1 as string)
         When cast(substr(cast(Format_date as string),6,2) as int) = 5 Then
                                        cast(cast(fin_year as int) - 1 as string)
         When cast(substr(cast(Format_date as string),6,2) as int) = 6 Then
                                        cast(cast(fin_year as int) - 1 as string)
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

Monthly_Date as (
    SELECT distinct
        MonthStartDate
    FROM Calendar_Data as A
    WHERE MonthStartDate >= cast('2021-04-01' as date) and
                                            MonthStartDate <= current_date),
/***********************************************************************
Collect the Permit 2019 data as benchmark
************************************************************************/
Permit_VRMS as (
    Select distinct new_vrm, new_make,new_model,new_fuel,new_engine_capactiy,
    new_co2_emission
    From liberator_permit_vrm_update
    WHERE import_date = (Select MAX(import_date) from
                                        liberator_permit_vrm_update)),
PERMIT_2019 as (
    SELECT
        permit_reference, application_date, vrm,
        cast(substr(cast(application_date as string), 1, 8)||'01' as date) as MonthDate,
        CASE
            When new_vrm is NULL Then fuel
            ELSE new_fuel
        END as Fuel,
        CASE
            When new_vrm is NULL Then engine_capactiy
            ELSE new_engine_capactiy
        END as engine_capactiy,
        CASE
            When new_vrm is NULL Then co2_emission
            ELSE new_co2_emission
        END as co2_emission
From parking_permit_denormalised_data as A
LEFT JOIN Permit_VRMS as B ON A.vrm = B.new_vrm
WHERE ImportDateTime = (Select MAX(ImportDateTime) from
                                        parking_permit_denormalised_data)
and cast(substr(cast(application_date as string), 1, 10) as date)
                between cast('2020-03-01' as date) and cast('2020-03-31' as date)
and permit_type != 'Dispensation' AND latest_permit_status not IN ('Cancelled','Rejected','RENEW_REJECTED')
AND cpz_name IN ('Zone A', 'Zone D','Zone F','Zone G','Zone G2','Zone H','Zone K','Zone L',
                'Zone N','Zone P','Zone Q','Zone S','Zone U','Zone T')),

Permit_2019_Summary as (
    SELECT
        MonthDate                                           as MonthStartDate,
        count(*)                                            as TotalPermits,
        SUM(CASE When Fuel = 'DIESEL' Then 1 Else 0 END)    as DieselPermitTotal,
        SUM(CASE When Fuel = 'ELECTRIC' Then 1 Else 0 END)  as ELECTRICPermitTotal,

        /*** Calc the percantage ***/
        (cast(count(*) as decimal(10,4)) - SUM(CASE When Fuel = 'DIESEL' Then 1 Else 0 END))
        /
        count(*)  as Percentage_Diff,
        /*** Calculate the percentage of Diesel Vehicles against Others ***/
        1-((cast(count(*) as decimal(10,4)) - SUM(CASE When Fuel = 'DIESEL' Then 1 Else 0 END))
        /
        count(*)) as Diesel_Percentage_Diff,
        /*** Calculate the percentage of Electric Vehicles against Others ***/
        1-((cast(count(*) as decimal(10,4)) - SUM(CASE When Fuel = 'ELECTRIC' Then 1 Else 0 END))
        /
        count(*)) as Electric_Percentage_Diff
    FROM PERMIT_2019
    GROUP BY MonthDate),

/********************************************************************************************************************
Collect the 'current' permit data, from 1st April 2021 (after COVID)
*********************************************************************************************************************/
Current_Permit as (
    SELECT *
    FROM parking_permit_denormalised_data as A
    LEFT JOIN Permit_VRMS as B ON A.vrm = B.new_vrm
    WHERE ImportDateTime = (Select MAX(ImportDateTime) from
                                            parking_permit_denormalised_data)
    AND permit_type != 'Dispensation' AND latest_permit_status not IN ('Cancelled','Rejected','RENEW_REJECTED')
    AND cpz_name IN ('Zone A', 'Zone D','Zone F','Zone G','Zone G2','Zone H','Zone K','Zone L',
                'Zone N','Zone P','Zone Q','Zone S','Zone U','Zone T')),

Permit_Summary as (
    SELECT
        permit_reference, application_date, vrm, start_date, end_date,
        cast(substr(cast(application_date as string), 1, 8)||'01' as date) as MonthDate,
        CASE
            When new_vrm is NULL Then fuel
            ELSE new_fuel
        END as Fuel,
        CASE
            When new_vrm is NULL Then engine_capactiy
            ELSE new_engine_capactiy
        END as engine_capactiy,
        CASE
            When new_vrm is NULL Then co2_emission
            ELSE new_co2_emission
        END as co2_emission
    FROM Current_Permit as A
    WHERE cast(substr(cast(application_date as string), 1, 10) as date) >=
                                                    cast('2021-04-01' as date)),

/*** Total the number of 'open' Permits & Diesel, etc Permits annd the 2019 data ***/
Permit_Report_ALL as (
    SELECT
        MonthDate,
        count(*)                                            as TotalPermits,
        SUM(CASE When Fuel = 'DIESEL' Then 1 Else 0 END)    as DieselPermitTotal,
        SUM(CASE When Fuel = 'ELECTRIC' Then 1 Else 0 END)  as ELECTRICPermitTotal,

        /*** Calc the percantage ***/
        (cast(count(*) as decimal(10,4)) - SUM(CASE When Fuel = 'DIESEL' Then 1 Else 0 END))
        /
        count(*)  as Percentage_Diff,
        /*** Calculate the percentage of Diesel Vehicles against Others ***/
        1-((cast(count(*) as decimal(10,4)) - SUM(CASE When Fuel = 'DIESEL' Then 1 Else 0 END))
        /
        count(*)) as Diesel_Percentage_Diff,
        /*** Calculate the percentage of Electric Vehicles against Others ***/
        1-((cast(count(*) as decimal(10,4)) - SUM(CASE When Fuel = 'ELECTRIC' Then 1 Else 0 END))
        /
        count(*)) as Electric_Percentage_Diff
    FROM Permit_Summary
    GROUP BY MonthDate
    UNION ALL
    SELECT * FROM Permit_2019_Summary
    ORDER BY MonthDate)

/*** REPORT OUTPUT ***/
SELECT
    *,
    current_timestamp()                            as ImportDateTime,
    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM Permit_Report_ALL
"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery14,
    mapping={
        "calendar": AmazonS3_node1658997944648,
        "liberator_permit_vrm_update": AmazonS3_node1658998021932,
        "parking_permit_denormalised_data": AmazonS3_node1658998139048,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Permit_diesel_Tends_Bought_in_Month/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Permit_diesel_Tends_Bought_in_Month",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
