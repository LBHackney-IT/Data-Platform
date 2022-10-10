import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var
environment = get_glue_env_var("environment")

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)

SqlQuery0 = '''
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
   --B.*
   FROM liberator_hangar_details as A
   --INNER JOIN HangarTypes as B ON A.id = B.id AND lower(A.hangar_type) = lower(B.hanger_class)
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
  SELECT *
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
SELECT A.ID, HANGER_ID, KEY_ID, SPACE, PARTY_ID, KEY_ISSUED, DATE_OF_ALLOCATION, ALLOCATION_STATUS, FEE_DUE_DATE, CREATED_BY,
       TITLE, FIRST_NAME, SURNAME, ADDRESS1, ADDRESS2, ADDRESS3, POSTCODE, TELEPHONE_NUMBER,
       /** Hangar details **/
       HANGAR_TYPE, IN_SERVICE, MAINTENANCE_KEY, SPACES, HANGAR_LOCATION, USRN, LATITUDE, LONGITUDE, START_OF_LIFE, END_OF_LIFE,
       import_year, import_month, import_day, import_date

FROM CycleHangarAllocation as A
LEFT JOIN HangarDetails as B ON A.HANGER_ID = B.HANGAR_ID AND B.ROW = 1
ORDER BY HANGER_ID, SPACE
'''

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_licence_party", transformation_ctx = "DataSource0"]
## @return: DataSource0
## @inputs: []
DataSource0 = glueContext.create_dynamic_frame.from_catalog(database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_licence_party", transformation_ctx = "DataSource0")
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_hangar_allocations", transformation_ctx = "DataSource3"]
## @return: DataSource3
## @inputs: []
DataSource3 = glueContext.create_dynamic_frame.from_catalog(database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_hangar_allocations", transformation_ctx = "DataSource3")
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_hangar_types", transformation_ctx = "DataSource2"]
## @return: DataSource2
## @inputs: []
DataSource2 = glueContext.create_dynamic_frame.from_catalog(database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_hangar_types", transformation_ctx = "DataSource2")
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_hangar_details", transformation_ctx = "DataSource1"]
## @return: DataSource1
## @inputs: []
DataSource1 = glueContext.create_dynamic_frame.from_catalog(database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_hangar_details", transformation_ctx = "DataSource1")
## @type: SqlCode
## @args: [sqlAliases = {"liberator_hangar_details": DataSource1, "liberator_hangar_types": DataSource2, "liberator_hangar_allocations": DataSource3, "liberator_licence_party": DataSource0}, sqlName = SqlQuery0, transformation_ctx = "Transform0"]
## @return: Transform0
## @inputs: [dfc = DataSource1,DataSource2,DataSource3,DataSource0]
Transform0 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"liberator_hangar_details": DataSource1, "liberator_hangar_types": DataSource2, "liberator_hangar_allocations": DataSource3, "liberator_licence_party": DataSource0}, transformation_ctx = "Transform0")
## @type: DataSink
## @args: [connection_type = "s3", catalog_database_name = "dataplatform-" + environment + "-liberator-refined-zone", format = "glueparquet", connection_options = {"path": "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_cycle_hangars_denormalisation/", "partitionKeys": ["import_year" ,"import_month" ,"import_day" ,"import_date"], "enableUpdateCatalog":true, "updateBehavior":"UPDATE_IN_DATABASE"}, catalog_table_name = "parking_cycle_hangars_denormalisation", transformation_ctx = "DataSink0"]
## @return: DataSink0
## @inputs: [frame = Transform0]
DataSink0 = glueContext.getSink(path = "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_cycle_hangars_denormalisation/", connection_type = "s3", updateBehavior = "UPDATE_IN_DATABASE", partitionKeys = ["import_year","import_month","import_day","import_date"], enableUpdateCatalog = True, transformation_ctx = "DataSink0")
DataSink0.setCatalogInfo(catalogDatabase = "dataplatform-" + environment + "-liberator-refined-zone",catalogTableName = "parking_cycle_hangars_denormalisation")
DataSink0.setFormat("glueparquet")
DataSink0.writeFrame(Transform0)

job.commit()