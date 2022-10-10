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
    table_name="liberator_permit_status",
    transformation_ctx="S3bucket_node1",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
--Latest permit status by status ID in latest partition import_date
Select s.*,concat(CAST(s.status_id AS STRING),CAST(s.permit_referece AS STRING),CAST(s.status_date AS STRING)) as latest_permitstatus_id 
,substr(s.permit_referece,1,3) as permit_type_prefix,
if(substr(s.permit_referece,1,3) = 'HYA','All zone',
if(substr(s.permit_referece,1,3) = 'HYG','Companion Badge',
if(substr(s.permit_referece,1,3) = 'HYB','Business',
if(substr(s.permit_referece,1,3) = 'HYD','Doctor',
if(substr(s.permit_referece,1,3) = 'HYP','Estate resident',
if(substr(s.permit_referece,1,3) = 'HYH','Health and social care',
if(substr(s.permit_referece,1,3) = 'HYR','Residents',
if(substr(s.permit_referece,1,3) = 'HYL','Leisure Centre Permit',
if(substr(s.permit_referece,1,3) = 'HYE','All Zone Business Voucher',
if(substr(s.permit_referece,1,3) = 'HYF','Film Voucher',
if(substr(s.permit_referece,1,3) = 'HYJ','Health and Social Care Voucher',
if(substr(s.permit_referece,1,3) = 'HYQ','Estate Visitor Voucher',
if(substr(s.permit_referece,1,3) = 'HYV','Resident Visitor Voucher',
if(substr(s.permit_referece,1,3)='HYN','Dispensation',
if(s.permit_referece ='HY50300','Dispensation',
substr(s.permit_referece,1,3)
))))))))))))))) as permit_type_category,

if(substr(s.permit_referece,1,3) ='HYE','Voucher',
if(substr(s.permit_referece,1,3)='HYF','Voucher',
if(substr(s.permit_referece,1,3)='HYQ','Voucher',
if(substr(s.permit_referece,1,3)='HYV','Voucher',
if(substr(s.permit_referece,1,3)='HYJ','Voucher',
if(substr(s.permit_referece,1,3)='HYN','Dispensation',
if(s.permit_referece ='HY50300','Dispensation',
if(substr(s.permit_referece,1,3)='HYS','Suspension','Permit'
)))))))) as product_category


FROM liberator_permit_status s

left Join
(select permit_referece, max(status_id) as max_status_id from liberator_permit_status Group by permit_referece) m on m.max_status_id = s.status_id

where m.max_status_id = s.status_id and s.import_date = (select max(import_date) from liberator_permit_status)

order by s.status_date desc, s.permit_referece, s.status_id desc

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"liberator_permit_status": S3bucket_node1},
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/dc_liberator_latest_permit_status/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="dc_liberator_latest_permit_status",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
