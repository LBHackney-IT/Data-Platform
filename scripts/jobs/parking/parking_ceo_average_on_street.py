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
AmazonS3_node1628173244776 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_ceo_on_street",
    transformation_ctx="AmazonS3_node1628173244776",
)

# Script generated for node Amazon S3
AmazonS3_node1632912445458 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_ceo_summary",
    transformation_ctx="AmazonS3_node1632912445458",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/******************************************************************************************************************************
Parking_CEO_Average_On_Street

This SQL creates the average CEO figures for time on street, breaks, etc

15/11/2021 - create SQL

******************************************************************************************************************************/

/******************************************************************************************************************************
Obtain the Time On Street Average
******************************************************************************************************************************/
with CEO_TimeOnStreet_Summary as (
   SELECT
      CEO, patrol_date,
      CAST(substr(cast(patrol_date as string), 1, 8)||'01' as date) as MonthYear,
      SUM(timeonstreet_secs) as CEODailyBeatTime_secs

   FROM parking_ceo_on_street
   WHERE import_Date = (Select MAX(import_date) from parking_ceo_on_street) and timeonstreet_secs > 0
   GROUP BY CEO, patrol_date
   order by CEO, patrol_date),

Monthly_AVG as (
   SELECT
      MonthYear, avg(CEODailyBeatTime_secs) as AVG_Month,
      CAST(from_unixtime(avg(CEODailyBeatTime_secs),'hh:mm:ss a') as string) as Format_Avg

   FROM CEO_TimeOnStreet_Summary
   GROUP BY MonthYear
   ORDER BY MonthYear),

/******************************************************************************************************************************
Get the time to the first Beat Street
******************************************************************************************************************************/   Start_Time as (
   SELECT
      CEO, patrol_date, officer_patrolling_date StartTime

   FROM parking_ceo_on_street
   WHERE import_Date = (Select MAX(import_date) from parking_ceo_on_street) AND beatname != ''
   AND Status_flag IN ('SSS')),

First_Street_Time as (
 SELECT
      CEO, patrol_date, MIN(officer_patrolling_date) FirstBeatStreet
   FROM parking_ceo_on_street
   WHERE import_Date = (Select MAX(import_date) from parking_ceo_on_street) AND beatname != ''
   AND Status_flag IN ('SS')
   GROUP BY CEO, patrol_date),

Time_To_Beat_Street as (
   SELECT
      A.CEO, A.patrol_date, CAST(substr(cast(A.patrol_date as string), 1, 8)||'01' as date) as MonthYear,
      StartTime, FirstBeatStreet,
      SUBSTRING(cast(unix_timestamp(FirstBeatStreet)-unix_timestamp(StartTime) as timestamp), 11) as Secs_to_First_Beat_Street

      /*date_diff('second',StartTime, FirstBeatStreet) as Secs_to_First_Beat_Street*/

   FROM Start_Time as A
   LEFT JOIN First_Street_Time as B ON A.CEO = B.CEO AND A.patrol_date = B.patrol_date),

AVG_Time_to_Beat as (
   SELECT
      MonthYear,
      CAST(from_unixtime(avg(Secs_to_First_Beat_Street),'hh:mm:ss a') as string) as Format_Total_Avg

   FROM Time_To_Beat_Street
   GROUP BY MonthYear),

/******************************************************************************************************************************
Get the Average amount of time CEO on Break and the average amoun of time CEO onStreet
******************************************************************************************************************************/
CEO_Break_Full as (
   SELECT
      officer_shoulder_no, ceo_protrol_date,
      CAST(substr(cast(ceo_protrol_date as string), 1, 8)||'01' as date) as MonthYear,
      total_break, timeonstreet_secs

   FROM parking_ceo_summary
   WHERE import_Date = (Select MAX(import_date) from parking_ceo_summary)),

Monthly_Break_AVG as (
   SELECT
      MonthYear,
      avg(total_break) as AVG_Break_Month,
      CAST(from_unixtime(avg(total_break),'hh:mm:ss a') as string) as Format_Break_Avg,
      avg(timeonstreet_secs) as AVG_Total_Month,
      CAST(from_unixtime(avg(timeonstreet_secs),'hh:mm:ss a') as string) as Format_Total_Avg

   FROM CEO_Break_Full
   GROUP BY MonthYear
   ORDER BY MonthYear)
/******************************************************************************************************************************
Output the data
******************************************************************************************************************************/
SELECT
   A.MonthYear,
   CAST(A.Format_Total_Avg as string) as Avg_Time_out,
   CAST(Format_Avg as string)         as Avg_Time_on_Beat,
   CAST(Format_Break_Avg as string)   as Avg_Break,
   CAST(C.Format_Total_Avg as string) as Avg_Time_to_Beat,

    current_timestamp() as ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date

FROM Monthly_Break_AVG as A
LEFT JOIN Monthly_AVG      as B ON A.MonthYear = B.MonthYear
LEFT JOIN AVG_Time_to_Beat as C ON A.MonthYear = C.MonthYear

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_ceo_on_street": AmazonS3_node1628173244776,
        "parking_ceo_summary": AmazonS3_node1632912445458,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_CEO_Average_On_Street/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_CEO_Average_On_Street",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
