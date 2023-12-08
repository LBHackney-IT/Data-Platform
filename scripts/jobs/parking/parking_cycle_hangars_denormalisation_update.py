import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS, create_pushdown_predicate_for_max_date_partition_value

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

# Script generated for node liberator_license_party
liberator_license_party_node1628255463015 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_licence_party",
        transformation_ctx="liberator_license_party_node1628255463015",
    )
)

# Script generated for node liberator_hangar_details
liberator_hangar_details_node1628254576316 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_hangar_details",
        transformation_ctx="liberator_hangar_details_node1628254576316",
    )
)

# Script generated for node liberator_hangar_types
liberator_hangar_types_node1628254679074 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_hangar_types",
        transformation_ctx="liberator_hangar_types_node1628254679074",
    )
)

# Script generated for node liberator_hangar_allocations
liberator_hangar_allocations_node1628254680802 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_hangar_allocations",
        transformation_ctx="liberator_hangar_allocations_node1628254680802",
    )
)

# Script generated for node ApplyMapping
SqlQuery52 = """
/***************************************************************************************************************************
Parking_cycle_hangar_denormalisation_update

The SQL creates the denormalised cycle hangar data (remove the duplicates). This is an updated code from Phil

07/12/2023 - create SQL
***************************************************************************************************************************/
WITH HangarTypes as (
   SELECT id, type_name, hanger_class, cost, cost_per,import_year, import_month, import_day
   FROM liberator_hangar_types 
   WHERE import_date = (SELECT MAX(import_date) FROM liberator_hangar_types)),


HangarDetails AS (
   SELECT A.ID ,
   HANGAR_TYPE ,
   HANGAR_ID ,
   IN_SERVICE ,
   MAINTENANCE_KEY ,
   SPACES ,
   HANGAR_LOCATION ,
   USRN ,
   LATITUDE ,
   LONGITUDE ,
   START_OF_LIFE ,
   END_OF_LIFE,
   import_date, import_year, import_month, import_day,
   ROW_NUMBER() OVER (PARTITION BY HANGAR_TYPE, HANGAR_ID, IN_SERVICE, MAINTENANCE_KEY, SPACES, HANGAR_LOCATION, USRN, LATITUDE,
                      LONGITUDE, START_OF_LIFE, END_OF_LIFE
            ORDER BY  HANGAR_TYPE, HANGAR_ID, IN_SERVICE, MAINTENANCE_KEY, SPACES, HANGAR_LOCATION, USRN, LATITUDE, LONGITUDE,
                      START_OF_LIFE, END_OF_LIFE DESC) AS ROW
   FROM liberator_hangar_details as A
   WHERE import_date = (SELECT MAX(import_date) FROM liberator_hangar_details)
   ORDER BY  HANGAR_ID),
        
        
HangarAllocBefore AS 
        (SELECT ID
              , HANGER_ID
              , KEY_ID
              , SPACE
              , PARTY_ID
              , KEY_ISSUED
              , DATE_OF_ALLOCATION
              , ALLOCATION_STATUS
              , FEE_DUE_DATE
              , CREATED_BY
              , ROW_NUMBER() OVER (PARTITION BY HANGER_ID, KEY_ID, SPACE, PARTY_ID, KEY_ISSUED, DATE_OF_ALLOCATION, ALLOCATION_STATUS,
                                   FEE_DUE_DATE, CREATED_BY
                ORDER BY  HANGER_ID, KEY_ID, SPACE, PARTY_ID, KEY_ISSUED, DATE_OF_ALLOCATION, ALLOCATION_STATUS, FEE_DUE_DATE, CREATED_BY
                                   DESC) AS ROW
        FROM liberator_hangar_allocations 
         WHERE import_date = (SELECT MAX(import_date) FROM liberator_hangar_allocations)),
                         
HangarAlloc AS 
        (SELECT *,
                ROW_NUMBER()
                OVER (PARTITION BY HANGER_ID, PARTY_ID
                ORDER BY  ID DESC) AS RW
        FROM HangarAllocBefore
        WHERE ROW =1),

licence_party as (
  SELECT party_id, business_party_id, title, first_name, surname,
        address1, address2, address3, postcode, uprn,
        telephone_number
  FROM liberator_licence_party 
  WHERE import_date = (SELECT MAX(import_date) FROM liberator_licence_party)),
                        
CycleHangarAllocation AS 
        (SELECT A.*,
         B.TITLE ,
         B.FIRST_NAME ,
         B.SURNAME ,
         B.ADDRESS1 ,
         B.ADDRESS2 ,
         B.ADDRESS3 ,
         B.POSTCODE ,
         B.TELEPHONE_NUMBER
         FROM HangarAlloc as A
         LEFT JOIN licence_party as B ON A.party_id = B.business_party_id
         WHERE RW = 1 AND Allocation_Status NOT IN ('cancelled', 'key_returned')
         ORDER BY  HANGER_ID, PARTY_ID, KEY_ISSUED, DATE_OF_ALLOCATION)

/*** Output the data ***/
SELECT 
	A.ID, HANGER_ID, KEY_ID, SPACE, PARTY_ID, KEY_ISSUED, DATE_OF_ALLOCATION, ALLOCATION_STATUS, FEE_DUE_DATE, CREATED_BY,
       TITLE, FIRST_NAME, SURNAME, ADDRESS1, ADDRESS2, ADDRESS3, POSTCODE, TELEPHONE_NUMBER,
       /** Hangar details **/
       HANGAR_TYPE, IN_SERVICE, MAINTENANCE_KEY, SPACES, HANGAR_LOCATION, USRN, LATITUDE, LONGITUDE, START_OF_LIFE, END_OF_LIFE,

    	current_timestamp()                            as ImportDateTime,
    	replace(cast(current_date() as string),'-','') as import_date,
    
    	cast(Year(current_date) as string)    as import_year, 
    	cast(month(current_date) as string)   as import_month, 
    	cast(day(current_date) as string)     as import_day
FROM CycleHangarAllocation as A
LEFT JOIN HangarDetails as B ON A.HANGER_ID = B.HANGAR_ID AND B.ROW = 1
ORDER BY HANGER_ID, SPACE
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery52,
    mapping={
        "liberator_hangar_details": liberator_hangar_details_node1628254576316,
        "liberator_hangar_types": liberator_hangar_types_node1628254679074,
        "liberator_hangar_allocations": liberator_hangar_allocations_node1628254680802,
        "liberator_licence_party": liberator_license_party_node1628255463015,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_cycle_hangars_denormalisation_update/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_cycle_hangars_denormalisation_update",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
