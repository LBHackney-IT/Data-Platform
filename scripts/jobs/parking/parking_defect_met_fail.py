import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
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
    database="parking-raw-zone",
    table_name="parking_parking_ops_db_defects_mgt",
    transformation_ctx="AmazonS3_node1658997944648",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
        "parking-raw-zone", "parking_parking_ops_db_defects_mgt", "import_date"
    ),
)

# Script generated for node SQL
SqlQuery33 = """
/*********************************************************************************
Parking_Defect_MET_FAIL

Temp SQL that formats the defcet managment records for Fail/Met

16/11/2022 - Create Query
15/01/2025 - found AND WHERE repair_date >= (??) removed AND
*********************************************************************************/
With Defect as (
SELECT
    reference_no,
    CAST(CASE
         When reported_date like '%0222%'Then   '2022-'||
                                                substr(reported_date, 7, 2)||'-'||
                                                substr(reported_date, 9, 2)

        When reported_date like '%/%'Then   substr(reported_date, 7, 4)||'-'||
                                            substr(reported_date, 4, 2)||'-'||
                                            substr(reported_date, 1, 2)
        ELSE substr(cast(reported_date as string),1, 10)
    END as date) as reported_date,
    CAST(CASE
         When repair_date like '%0222%'Then   '2022-'||
                                                substr(repair_date, 7, 2)||'-'||
                                                substr(repair_date, 9, 2)

        When reported_date like '%/%'Then   substr(repair_date, 7, 4)||'-'||
                                            substr(repair_date, 4, 2)||'-'||
                                            substr(repair_date, 1, 2)
        ELSE substr(cast(repair_date as string),1, 10)
    END as date) as repair_date,
    category,
    date_wo_sent,
    expected_wo_completion_date, target_turn_around, met_not_met,
    full_repair_category,
    issue, engineer

FROM parking_parking_ops_db_defects_mgt
WHERE import_date = (Select MAX(import_date) from parking_parking_ops_db_defects_mgt)
AND length(ltrim(rtrim(reported_date))) > 0
AND met_not_met not IN ('#VALUE!','#N/A') /*('N/A','#N/A','#VALUE!')*/)

SELECT
    *,
    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date
FROM Defect
WHERE repair_date >=
    date_add(cast(substr(cast(current_date as string), 1, 8)||'01' as date), -365)


"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery33,
    mapping={"parking_parking_ops_db_defects_mgt": AmazonS3_node1658997944648},
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Defect_MET_FAIL/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Defect_MET_FAIL",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
