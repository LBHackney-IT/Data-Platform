import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import create_pushdown_predicate, get_glue_env_var

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

# Script generated for node S3 - liberator_refined - parking_permit_denormalised_gds_street_llpg
S3liberator_refinedparking_permit_denormalised_gds_street_llpg_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_permit_denormalised_gds_street_llpg",
    transformation_ctx="S3liberator_refinedparking_permit_denormalised_gds_street_llpg_node1",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node Amazon S3
AmazonS3_node1647531223393 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="school_street_uprn",
    transformation_ctx="AmazonS3_node1647531223393",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*********************************************************************************
Parking_School_Street_VRMs

This SQL creates the list of VRMs against the current valid Permits

02/03/2022 - Create Query
*********************************************************************************/
With Excluded_UPRNs as (
   SELECT uprn as excluded_uprns, excluded_location
   FROM school_street_uprn)

Select
   permit_reference,
   cast(application_date as timestamp)                          as application_date,
   cast(substr(cast(start_date as varchar(10)), 1, 10) as date) as start_date,
   cast(substr(cast(end_date as varchar(10)), 1, 10) as date)   as end_date,
   A.uprn,
   vrm,
   make, model, fuel, engine_capactiy, co2_emission,

   excluded_location as SS_Location, status,

   current_timestamp as ImportDateTime,

   import_date,
   import_year,
   import_month,
   import_day

   FROM parking_permit_denormalised_gds_street_llpg as A
   INNER JOIN Excluded_UPRNs as B ON A.uprn = B.excluded_uprns
   Where Import_date =
        (Select MAX(Import_date) FROM parking_permit_denormalised_gds_street_llpg)
   AND substr(permit_reference,1,3) IN ('HYR', 'HYG','HYP')

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_permit_denormalised_gds_street_llpg": S3liberator_refinedparking_permit_denormalised_gds_street_llpg_node1,
        "school_street_uprn": AmazonS3_node1647531223393,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_School_Street_VRMs/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_School_Street_VRMs",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
