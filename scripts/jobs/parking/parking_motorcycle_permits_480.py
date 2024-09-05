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
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
environment = get_glue_env_var("environment")

# Script generated for node Amazon S3 - liberator_permit_vrm_480
AmazonS3liberator_permit_vrm_480_node1725467933869 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-raw-zone", table_name="liberator_permit_vrm_480", transformation_ctx="AmazonS3liberator_permit_vrm_480_node1725467933869")

# Script generated for node Amazon S3 - parking_permit_denormalised_gds_street_llpg
AmazonS3parking_permit_denormalised_gds_street_llpg_node1725467934601 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-refined-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="parking_permit_denormalised_gds_street_llpg", transformation_ctx="AmazonS3parking_permit_denormalised_gds_street_llpg_node1725467934601")

# Script generated for node Amazon S3 - liberator_permit_vrm_update_480
AmazonS3liberator_permit_vrm_update_480_node1725468292784 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-raw-zone", table_name="liberator_permit_vrm_update_480", transformation_ctx="AmazonS3liberator_permit_vrm_update_480_node1725468292784")

# Script generated for node SQL Query - Pemit match to 480 Motorcycle flag
SqlQuery0 = '''
/*
All Permits data in latest import_date matched to all is_motorcycle like 'Y' in the VRM_480 and VRM_update_480 tables
04/09/2024 - Created
*/

with lp as (
SELECT distinct concat(permit_reference,vrm) as unique_perm_vrm,*  FROM  parking_permit_denormalised_gds_street_llpg
where import_date = (SELECT max(import_date)  FROM parking_permit_denormalised_gds_street_llpg)
)
, vrm_mc_all as (select distinct --import_date as vrm_import_date, vrm, 
concat(permit_reference,vrm) as unique_perm_vrm,
is_motorcycle from liberator_permit_vrm_480 where is_motorcycle like 'Y' --or is_motorcycle like 'N'  --and import_date = (select max(import_date) from "dataplatform-prod-liberator-raw-zone".liberator_permit_vrm_480)

Union All
select distinct concat(permit_reference,new_vrm) as unique_perm_vrm, is_motorcycle from liberator_permit_vrm_update_480 where is_motorcycle like 'Y' -- and import_date = (select max(import_date) from "dataplatform-prod-liberator-raw-zone".liberator_permit_vrm_update_480)
)

Select distinct vrm_mc_all.is_motorcycle, lp.* from vrm_mc_all
left join lp on vrm_mc_all.unique_perm_vrm = lp.unique_perm_vrm
order by lp.application_date asc
'''
SQLQueryPemitmatchto480Motorcycleflag_node1725467937913 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"parking_permit_denormalised_gds_street_llpg":AmazonS3parking_permit_denormalised_gds_street_llpg_node1725467934601, "liberator_permit_vrm_480":AmazonS3liberator_permit_vrm_480_node1725467933869, "liberator_permit_vrm_update_480":AmazonS3liberator_permit_vrm_update_480_node1725468292784}, transformation_ctx = "SQLQueryPemitmatchto480Motorcycleflag_node1725467937913")

# Script generated for node Amazon S3 - parking_motorcycle_permits_480
AmazonS3parking_motorcycle_permits_480_node1725467946706 = glueContext.getSink(path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_motorcycle_permits_480/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=["import_year", "import_month", "import_day", "import_date"], enableUpdateCatalog=True, transformation_ctx="AmazonS3parking_motorcycle_permits_480_node1725467946706")
AmazonS3parking_motorcycle_permits_480_node1725467946706.setCatalogInfo(catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",catalogTableName="parking_motorcycle_permits_480")
AmazonS3parking_motorcycle_permits_480_node1725467946706.setFormat("glueparquet", compression="snappy")
AmazonS3parking_motorcycle_permits_480_node1725467946706.writeFrame(SQLQueryPemitmatchto480Motorcycleflag_node1725467937913)
job.commit()
