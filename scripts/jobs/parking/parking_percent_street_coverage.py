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
    table_name="parking_deployment_target_details",
    transformation_ctx="AmazonS3_node1628173244776",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/******************************************************************************************************************************
Parking_Percent_Street_Coverage

This SQL creates the street % coverage by CEO

26/11/2021 - create SQL
******************************************************************************************************************************/
WITH Target_Actual as (
   SELECT
      month, cpz,
      cast(SUM(mfam+mfpm+mfev+mfat) as double)                 as Mon_Fri,
      cast(cast(SUM(satam+satpm+satev) as int) as double)      as Sat,
      cast(SUM(act_mfam+act_mfpm+act_mfev+act_mfat) as double) as Act_Mon_Fri,
      cast(SUM(act_satam+act_satpm+act_satev) as double)       as Act_Sat
   FROM parking_deployment_target_details
   WHERE import_date = (Select MAX(import_date) from parking_deployment_target_details)
   AND cpz != 'Estates'
   GROUP BY month, cpz),
/*** Summerise the Mon-Fri & Sat totals into a Single Monthly Target ***/
Monthly_Totals as (
   SELECT
      month,
      SUM(Mon_Fri+Sat)          as zone_Target,
      SUM(Act_Mon_Fri +Act_Sat) as zone_actual
   FROM Target_Actual
   GROUP BY month
order by month)
/*** Calculate the coverage percentage ***/
SELECT
   month,
   Zone_Target as Monthly_NoStreets_Target,
   zone_actual as Monthly_NoStreets_Actual,
   round(((zone_actual - zone_target) / zone_target)*100, 2)+100 as Percentage_Coverage,

    current_timestamp() as ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date
FROM Monthly_Totals
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"parking_deployment_target_details": AmazonS3_node1628173244776},
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Percent_Street_Coverage/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Percent_Street_Coverage",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
