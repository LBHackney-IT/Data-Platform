import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS


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

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="S3bucket_node1",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
with sr as (--llpg_streets_records:
select  
    UPRN as SR_UPRN,
	ADDRESS1 as SR_ADDRESS1,
	ADDRESS2 as SR_ADDRESS2,
	ADDRESS3 as SR_ADDRESS3,
	ADDRESS4 as SR_ADDRESS4,
	ADDRESS5 as SR_ADDRESS5,
	POST_CODE as SR_POST_CODE,
	BPLU_CLASS as SR_BPLU_CLASS,
	X as SR_X,
	Y as SR_Y,
	LATITUDE as SR_LATITUDE,
	LONGITUDE as SR_LONGITUDE,
	IN_CONGESTION_CHARGE_ZONE as SR_IN_CONGESTION_CHARGE_ZONE,
	CPZ_CODE as SR_CPZ_CODE,
	CPZ_NAME as SR_CPZ_NAME,
	LAST_UPDATED_STAMP as SR_LAST_UPDATED_STAMP,
	LAST_UPDATED_TX_STAMP as SR_LAST_UPDATED_TX_STAMP,
	CREATED_STAMP as SR_CREATED_STAMP,
	CREATED_TX_STAMP as SR_CREATED_TX_STAMP,
	HOUSE_NAME as SR_HOUSE_NAME,
	POST_CODE_PACKED as SR_POST_CODE_PACKED,
	STREET_START_X as SR_STREET_START_X,
	STREET_START_Y as SR_STREET_START_Y,
	STREET_END_X as SR_STREET_END_X,
	STREET_END_Y as SR_STREET_END_Y,
	WARD_CODE as SR_WARD_CODE,
if(WARD_CODE = 'E05009367',    'BROWNSWOOD WARD',    
if(WARD_CODE = 'E05009368',    'CAZENOVE WARD',    
if(WARD_CODE = 'E05009369',    'CLISSOLD WARD',    
if(WARD_CODE = 'E05009370',    'DALSTON WARD',    
if(WARD_CODE = 'E05009371',    'DE BEAUVOIR WARD',    
if(WARD_CODE = 'E05009372',    'HACKNEY CENTRAL WARD',    
if(WARD_CODE = 'E05009373',    'HACKNEY DOWNS WARD',    
if(WARD_CODE = 'E05009374',    'HACKNEY WICK WARD',    
if(WARD_CODE = 'E05009375',    'HAGGERSTON WARD',    
if(WARD_CODE = 'E05009376',    'HOMERTON WARD',    
if(WARD_CODE = 'E05009377',    'HOXTON EAST AND SHOREDITCH WARD',    
if(WARD_CODE = 'E05009378',    'HOXTON WEST WARD',    
if(WARD_CODE = 'E05009379',    'KINGS PARK WARD',    
if(WARD_CODE = 'E05009380',    'LEA BRIDGE WARD',    
if(WARD_CODE = 'E05009381',    'LONDON FIELDS WARD',    
if(WARD_CODE = 'E05009382',    'SHACKLEWELL WARD',    
if(WARD_CODE = 'E05009383',    'SPRINGFIELD WARD',    
if(WARD_CODE = 'E05009384',    'STAMFORD HILL WEST',    
if(WARD_CODE = 'E05009385',    'STOKE NEWINGTON WARD',    
if(WARD_CODE = 'E05009386',    'VICTORIA WARD',    
if(WARD_CODE = 'E05009387',    'WOODBERRY DOWN WARD',WARD_CODE))))))))))))))))))))) as SR_ward_name, 	 
	PARISH_CODE as SR_PARISH_CODE,
	PARENT_UPRN as SR_PARENT_UPRN,
	PAO_START as SR_PAO_START,
	PAO_START_SUFFIX as SR_PAO_START_SUFFIX,
	PAO_END as SR_PAO_END,
	PAO_END_SUFFIX as SR_PAO_END_SUFFIX,
	PAO_TEXT as SR_PAO_TEXT,
	SAO_START as SR_SAO_START,
	SAO_START_SUFFIX as SR_SAO_START_SUFFIX,
	SAO_END as SR_SAO_END,
	SAO_END_SUFFIX as SR_SAO_END_SUFFIX,
	SAO_TEXT as SR_SAO_TEXT,
	DERIVED_BLPU as SR_DERIVED_BLPU,
	USRN
,import_year
,import_month
,import_day
,import_date
FROM liberator_permit_llpg
where (ADDRESS1 like 'Street Record' or ADDRESS1 like 'STREET RECORD') and import_date = (SELECT MAX(import_date) FROM liberator_permit_llpg)
)
Select liberator_permit_llpg.uprn, liberator_permit_llpg.usrn, SR_ADDRESS1, SR_ADDRESS2, SR_ADDRESS3, SR_ADDRESS4, SR_ADDRESS5, SR_POST_CODE, SR_BPLU_CLASS, SR_X, SR_Y, SR_LATITUDE, SR_LONGITUDE, SR_IN_CONGESTION_CHARGE_ZONE, SR_CPZ_CODE, SR_CPZ_NAME, SR_LAST_UPDATED_STAMP, SR_LAST_UPDATED_TX_STAMP, SR_CREATED_STAMP, SR_CREATED_TX_STAMP, SR_HOUSE_NAME, SR_POST_CODE_PACKED, SR_STREET_START_X, SR_STREET_START_Y, SR_STREET_END_X, SR_STREET_END_Y, SR_WARD_CODE, SR_ward_name, SR_PARISH_CODE, SR_PARENT_UPRN, SR_PAO_START, SR_PAO_START_SUFFIX, SR_PAO_END, SR_PAO_END_SUFFIX, SR_PAO_TEXT, SR_SAO_START, SR_SAO_START_SUFFIX, SR_SAO_END, SR_SAO_END_SUFFIX, SR_SAO_TEXT, SR_DERIVED_BLPU
,liberator_permit_llpg.import_year
,liberator_permit_llpg.import_month
,liberator_permit_llpg.import_day
,liberator_permit_llpg.import_date

FROM liberator_permit_llpg
Left join sr on sr.usrn = liberator_permit_llpg.usrn
where liberator_permit_llpg.import_date = (SELECT MAX(liberator_permit_llpg.import_date) FROM liberator_permit_llpg)
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"liberator_permit_llpg": S3bucket_node1},
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/dc_liberator_permit_llpg_street_records/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="dc_liberator_permit_llpg_street_records",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
