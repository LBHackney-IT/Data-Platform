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
    table_name="liberator_hangar_waiting_list",
    transformation_ctx="AmazonS3_node1658997944648",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
        "dataplatform-" + environment + "-liberator-raw-zone",
        "liberator_hangar_waiting_list",
        "import_date",
    ),
)

# Script generated for node Amazon S3
AmazonS3_node1685714415298 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="AmazonS3_node1685714415298",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
        "dataplatform-" + environment + "-liberator-raw-zone",
        "liberator_permit_llpg",
        "import_date",
    ),
)

# Script generated for node Amazon S3
AmazonS3_node1685714634970 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_hangar_allocations",
    transformation_ctx="AmazonS3_node1685714634970",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
        "dataplatform-" + environment + "-liberator-raw-zone",
        "liberator_hangar_allocations",
        "import_date",
    ),
)

# Script generated for node Amazon S3
AmazonS3_node1685714303815 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_party",
    transformation_ctx="AmazonS3_node1685714303815",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value(
        "dataplatform-" + environment + "-liberator-raw-zone",
        "liberator_licence_party",
        "import_date",
    ),
    additional_options={"mergeSchema": "true"},
)

# Script generated for node SQL
SqlQuery67 = """
/********************************************************************************************************************
Parking_Cycle_Hangar_Wait_List

The SQL tidies the Cycle Hangar waiting list, It will create a single record for each Party ID on the list

02/06/2023 - Create Query
09/06/2023 - add X & Y from LLPG
12/10/2023 - Add the different types of hangars requested by the party
********************************************************************************************************************/
/*** Waiting List ***/
WITH waiting_list as (
    SELECT *,
        ROW_NUMBER() OVER ( PARTITION BY party_id
                            ORDER BY party_id DESC) row1
    FROM liberator_hangar_waiting_list
    WHERE Import_Date = (Select MAX(Import_Date) from
                                liberator_hangar_waiting_list)),
/*** Party List ***/
Licence_Party as (
    SELECT *
    FROM liberator_licence_party
    WHERE Import_Date = (Select MAX(Import_Date) from
                                    liberator_licence_party)),
/*** STREET ***/
LLPG as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from
                                       liberator_permit_llpg)),
/*******************************************************************************
Cycle Hangar allocation details
*******************************************************************************/
Cycle_Hangar_allocation as (
    SELECT
        *,
        ROW_NUMBER() OVER ( PARTITION BY party_id
        ORDER BY party_id, date_of_allocation DESC) row_num
    FROM liberator_hangar_allocations
    WHERE Import_Date = (Select MAX(Import_Date) from
                                  liberator_hangar_allocations)
    AND allocation_status IN ('live')),

Street_Rec as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from
                                       liberator_permit_llpg)
    AND address1 = 'STREET RECORD'),

/** Obtain the unique Party IDs **/
Party_ID_List as (
    SELECT
        A.party_id, first_name, surname, B.uprn as USER_UPRN,
        B.address1, B.address2, B.address3, B.postcode,
        B.telephone_number, D.Address2 as Street, email_address,
        B.record_created as Date_Registered,
        C.x, C.y
    FROM waiting_list as A
    LEFT JOIN Licence_Party as B ON A.party_id = B.business_party_id
    LEFT JOIN LLPG          as C ON B.uprn = cast(C.UPRN as string)
    LEFT JOIN Street_Rec    as D ON C.USRN = D.USRN
    LEFT JOIN Cycle_Hangar_allocation as E ON A.party_id = E.party_id AND row_num = 1
    WHERE row1= 1 AND E.party_id is NULL and D.Address2 is not NULL),

Count_Hangar_Details as (
    SELECT party_id,
        SUM(CASE
            When registration_type = 'ESTATE' Then 1
            ELSE 0
            END) as Estate_Count,
          SUM(CASE
            When registration_type = 'NEWONLY' Then 1
            ELSE 0
            END) as Newonly_Count,
          SUM(CASE
            When registration_type = 'RESIDENT' Then 1
            ELSE 0
            END) as Resident_Count
    FROM waiting_list
    GROUP BY party_id)

SELECT A.*, B.Estate_Count, B.Newonly_Count, B.Resident_Count,

    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS importdatetime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date

FROM Party_ID_List as A
LEFT JOIN Count_Hangar_Details as B ON A.party_id = B.party_id
"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery67,
    mapping={
        "liberator_hangar_waiting_list": AmazonS3_node1658997944648,
        "liberator_licence_party": AmazonS3_node1685714303815,
        "liberator_permit_llpg": AmazonS3_node1685714415298,
        "liberator_hangar_allocations": AmazonS3_node1685714634970,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/parking_cycle_hangars_waiting_list/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_cycle_hangars_waiting_list",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
