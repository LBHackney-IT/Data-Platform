import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    create_pushdown_predicate,
    create_pushdown_predicate_for_max_date_partition_value,
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
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_activity",
    transformation_ctx="AmazonS3_node1658997944648",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node Amazon S3
AmazonS3_node1661350417347 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_suspension_denormalised_data",
    transformation_ctx="AmazonS3_node1661350417347",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node SQL
SqlQuery177 = """
/*********************************************************************************
Parking_Suspensions_Processed

SQL TO create the suspension processed, to identify the No. od days that a
Suspension takes to be processed to accept/amend/reject/etc.

19/10/2022 - Create Query
*********************************************************************************/
/** Obtain the Suspension activity **/
With Sus_Activity as (
    SELECT
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, activity_date ASC) row_num
    FROM liberator_permit_activity
    WHERE import_date = (Select MAX(import_date)
                                from liberator_permit_activity)
    AND permit_referece like 'HYS%'
    AND (lower(activity) like '%approved%' OR lower(activity) like '%rejected%'
            OR lower(activity) like '%amend%' OR lower(activity) like '%additional%')),

/** Link the earliest activity to a suspension, obtain the days diff **/
Suspensions as (
    select
        suspensions_reference,
        applicationdate,
        activity_date,
        datediff(activity_date,applicationdate) as DateDiff,
        activity, activity_by
    From parking_suspension_denormalised_data as A
    INNER JOIN Sus_Activity as B ON A.suspensions_reference = B.permit_referece AND B.row_num = 1
    WHERE import_date = (Select MAX(import_date) from parking_suspension_denormalised_data)
    )

/** Output the data **/
SELECT
    *,

    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date
FROM Suspensions

"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery177,
    mapping={
        "liberator_permit_activity": AmazonS3_node1658997944648,
        "parking_suspension_denormalised_data": AmazonS3_node1661350417347,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Suspensions_Processed/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Suspensions_Processed",
)
AmazonS3_node1658765590649.setFormat("glueparquet", compression="snappy")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
