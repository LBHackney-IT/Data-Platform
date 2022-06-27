import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var
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

# Script generated for node Amazon S3
AmazonS3_node1625732651466 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3_node1625732651466",
)

# Script generated for node Amazon S3
AmazonS3_node1646229922398 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_tickets",
    transformation_ctx="AmazonS3_node1646229922398",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*************************************************************************************************************************
Parking_Foreign_VRM_PCNs 

This SQL creates the list of VRMs against the current valid Permits

02/03/2022 - Create Query
*************************************************************************************************************************/
/* Collect the Foreign PCNs from the raw PCN data */
With PCN_Raw as (
select * from liberator_pcn_tickets
Where Import_Date = (Select MAX(Import_Date) 
        from liberator_pcn_tickets) and lower(foreignvehiclecountry) = 'y')

SELECT 
   PCN, cast(pcnissuedatetime as timestamp) as pcnissuedatetime, pcn_canx_date, A.cancellationgroup, 
   A.cancellationreason, street_location,
   whereonlocation, zone, usrn, A.contraventioncode, debttype, A.vrm, vehiclemake, vehiclemodel,
   vehiclecolour, ceo, isremoval, A.progressionstage, lib_payment_received as payment_received,
   whenpaid as PaymentDate, noderef, replace(replace(ticketnotes, '\r',''), '\n','') as ticketnotes,
   
   current_timestamp() as ImportDateTime,
    
   replace(cast(current_date() as string),'-','') as import_date,
    
   -- Add the Import date
   cast(Year(current_date) as string)  as import_year, 
   cast(month(current_date) as string) as import_month,
   cast(day(current_date) as string)   as import_day   
   
   
   FROM pcnfoidetails_pcn_foi_full as A
   INNER JOIN PCN_Raw as B ON A.pcn = B.ticketserialnumber
   Where ImportDateTime = (Select MAX(ImportDateTime) from pcnfoidetails_pcn_foi_full) and warningflag = 0
   Order By pcnissuedatetime
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "pcnfoidetails_pcn_foi_full": AmazonS3_node1625732651466,
        "liberator_pcn_tickets": AmazonS3_node1646229922398,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Foreign_VRM_PCNs/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Foreign_VRM_PCNs",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
