import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import PARTITION_KEYS, get_glue_env_var, create_pushdown_predicate_for_max_date_partition_value



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
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-" + environment + "-liberator-raw-zone", "liberator_hangar_waiting_list", 'import_date')
)

# Script generated for node Amazon S3
AmazonS3_node1685714415298 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="AmazonS3_node1685714415298",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-" + environment + "-liberator-raw-zone", "liberator_permit_llpg", 'import_date')
)

# Script generated for node Amazon S3
AmazonS3_node1685714634970 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_hangar_allocations",
    transformation_ctx="AmazonS3_node1685714634970",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-" + environment + "-liberator-raw-zone", "liberator_hangar_allocations", 'import_date')
)

# Script generated for node Amazon S3
AmazonS3_node1685714303815 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_party",
    transformation_ctx="AmazonS3_node1685714303815",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-" + environment + "-liberator-raw-zone", "liberator_licence_party", 'import_date')
)

# Script generated for node SQL
SqlQuery67 = """
/********************************************************************************************************************
Parking_Cycle_Hangar_Wait_List

The SQL tidies the Cycle Hangar waiting list, It will create a single record for each Party ID on the list

02/06/2023 - Create Query
09/06/2023 - add X & Y from LLPG
********************************************************************************************************************/
/*** Waiting List ***/
WITH waiting_list as (
    SELECT *,
        ROW_NUMBER() OVER ( PARTITION BY party_id 
                            ORDER BY party_id DESC) row1
    FROM liberator_hangar_waiting_list
),
    
/*** Party List ***/
Licence_Party as (
    SELECT * 
    FROM liberator_licence_party 
),
/*** STREET ***/
LLPG as (
    SELECT *
    FROM liberator_permit_llpg
),
/*******************************************************************************
Cycle Hangar allocation details
*******************************************************************************/ 
Cycle_Hangar_allocation as (
    SELECT 
        *,
        ROW_NUMBER() OVER ( PARTITION BY party_id
        ORDER BY party_id, date_of_allocation DESC) row_num
    FROM liberator_hangar_allocations
    WHERE allocation_status IN ('live')
),

Street_Rec as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE address1 = 'STREET RECORD'
)
    
/**** OUTPUT THE DATA ****/
SELECT
    A.party_id, first_name, surname, B.uprn as user_uprn,
    B.address1, B.address2, B.address3, B.postcode, 
    B.telephone_number,
    D.Address2 as street,
    C.x, C.y, 
    
    current_timestamp() as importdatetime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    cast(Year(current_date) as string)    as import_year, 
    cast(month(current_date) as string)   as import_month, 
    cast(day(current_date) as string)     as import_day
    
FROM waiting_list as A
LEFT JOIN Licence_Party as B ON A.party_id = B.business_party_id
LEFT JOIN LLPG as C ON B.uprn = cast(C.UPRN as string)
LEFT JOIN Street_Rec    as D ON C.USRN = D.USRN
LEFT JOIN Cycle_Hangar_allocation as E ON A.party_id = E.party_id AND row_num = 1
WHERE row1= 1 AND E.party_id is NULL and D.Address2 is not NULL
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
    path="s3://dataplatform-" + environment + "-refined-zone/parking/parking_cycle_hangar_waiting_list/parking_cycle_hangar_waiting_list_with_coordinates/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_cycle_hangar_waiting_list_with_coordinates",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
