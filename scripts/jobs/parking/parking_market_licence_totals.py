import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

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
AmazonS3_node1636704737623 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1636704737623",
)

# Script generated for node Amazon S3
AmazonS3_node1638358321513 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_licence_full",
    transformation_ctx="AmazonS3_node1638358321513",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*************************************************************************************************************************
Parking_Market_Licence_Totals

The SQL builds the total number of Market trader licences extant on the 28th of each month

02/12/2021 - Create SQL.
*************************************************************************************************************************/
/*** Collect the 28th day of each month ***/
With Calendar_Data as (
   SELECT
      date as Calendar_date, workingday, dow, holiday,

      ROW_NUMBER() OVER ( PARTITION BY date ORDER BY  date, import_date DESC) row_num

   FROM calendar
   WHERE date like '%28%'),
/*** Format the calendar date ***/
CalendarFormat as (
   SELECT
      Calendar_date,
      CAST(CASE
         When Calendar_date like '%/%'Then substr(Calendar_date, 7, 4)||'-'||
                                           substr(Calendar_date, 4, 2)||'-'||substr(Calendar_date, 1, 2)
         ELSE substr(Calendar_date, 1, 10)
      END as date) as Format_date
   FROM Calendar_Data
   WHERE row_num = 1),

/*** rework the Requested date as some oof the records are PANTS! ***/
Format_Requested_Date as (
   SELECT
      licence_ref,

      /*** rework the Requested date as some oof the records are PANTS! ***/
      CAST(CASE
         When requested_start_date is NULL      Then substr(cast(application_date as string), 1,10)
         When length(requested_start_date) < 10 Then substr(cast(application_date as string), 1,10)
         When requested_start_date like '%.%'   Then substr(cast(application_date as string), 1,10)
         When requested_start_date like '%/%'Then
            CASE
               When substr(requested_start_date, 7,4) = '1900' Then substr(cast(application_date as string), 1,10)

               When cast(substr(requested_start_date, 4,2) as int) > 12 Then substr(cast(application_date as string), 1,10)

            ELSE substr(requested_start_date, 7,4)||'-'||
                 substr(requested_start_date, 4,2)||'-'||
                 substr(requested_start_date, 1,2)
            END
         ELSE substr(requested_start_date, 1, 10)
         END as date) as requested_start_date

      FROM liberator_licence_licence_FULL
      WHERE import_Date = (Select MAX(import_date) from liberator_licence_licence_full) and licence_ref like 'MAR%'),

/*** Get the Market data ***/
Market_Before as (
   SELECT
      A.licence_ref, licence_type, licence_address, application_date,

      CASE
         When lower(licence_type) = lower('MARKET-newtemp')   Then 'Temp'
         When lower(licence_type) = lower('MARKET-renewperm') Then 'Perm'
         When lower(licence_type) = lower('MARKET-renewtemp') Then 'Temp'
         ELSE 'Temp'
      END as Licence_Type_PermTemp,

      B.requested_start_date,

      /*** rework the Actual date as some oof the records are PANTS! ***/

      CAST(CASE
         When actual_start_date is NULL      Then substr(cast(B.requested_start_date as string), 1,10)
         When length(actual_start_date) < 10 Then substr(cast(B.requested_start_date as string), 1,10)
         When actual_start_date like '%.%'   Then substr(cast(B.requested_start_date as string), 1,10)
         When actual_start_date like '%/%'Then
            CASE
               When substr(actual_start_date, 7,4) = '1900' Then substr(cast(B.requested_start_date as string), 1,10)

               When cast(substr(actual_start_date, 4,2) as int) > 12 Then substr(cast(B.requested_start_date as string), 1,10)

            ELSE substr(actual_start_date, 7,4)||'-'||
                 substr(actual_start_date, 4,2)||'-'||
                 substr(actual_start_date, 1,2)
            END
         ELSE substr(actual_start_date, 1, 10)
         END as date) as actual_start_date

   FROM liberator_licence_licence_FULL as A
   LEFT JOIN Format_Requested_Date as B ON A.licence_ref = B.licence_ref
   WHERE import_Date = (Select MAX(import_date) from liberator_licence_licence_full) and A.licence_ref like 'MAR%'),

Market as (
   SELECT
      *,
      CAST(CASE
         When Licence_Type_PermTemp = 'Temp' Then date_add(actual_start_date, 183)
         When Licence_Type_PermTemp = 'Perm' Then date_add(actual_start_date, 365)
       END as date) as End_Date,

      cast(substr(cast(actual_start_date as string), 1, 8)||'01' as date) as MonthYear

   from Market_Before),

/** total the number of 'temp' licences active on the 28th of each month **/
Temp_Market as (
   Select
      Format_date,
      count(*) as No_Temp_Licences

   From CalendarFormat as A, Market as B
   Where A.Format_date between B.actual_start_date and B.End_Date AND Licence_Type_PermTemp = 'Temp'
   group by Format_date),

/** total the number of 'temp' licences active on the 28th of each month **/
Perm_Market as (
   Select
      Format_date,
      count(*) as No_Perm_Licences

   From CalendarFormat as A, Market as B
   Where A.Format_date between B.actual_start_date and B.End_Date AND Licence_Type_PermTemp = 'Perm'
   group by Format_date)

/*** Output the results ***/
SELECT
   A.Format_date,
   No_Temp_Licences,
   No_Perm_Licences,

   date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
   date_format(current_date, 'yyyy') AS import_year,
   date_format(current_date, 'MM') AS import_month,
   date_format(current_date, 'dd') AS import_day,
   date_format(current_date, 'yyyyMMdd') AS import_date

FROM Temp_Market as A
LEFT JOIN Perm_Market as B ON A.Format_date = B.Format_date
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "calendar": AmazonS3_node1636704737623,
        "liberator_licence_licence_FULL": AmazonS3_node1638358321513,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Market_Licence_Totals/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Market_Licence_Totals",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
