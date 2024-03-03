import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, create_pushdown_predicate
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
AmazonS3_node1648207907397 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_voucher",
    transformation_ctx="AmazonS3_node1648207907397",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node Amazon S3
AmazonS3_node1648208237020 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_fta",
    transformation_ctx="AmazonS3_node1648208237020",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node Amazon S3
AmazonS3_node1648208633220 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_printing",
    transformation_ctx="AmazonS3_node1648208633220",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node Amazon S3
AmazonS3_node1649411092913 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_evouchersession",
    transformation_ctx="AmazonS3_node1649411092913",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*********************************************************************************
Parking_Voucher_De_Normalised

This SQL creates a denormalised list of Vouchers

23/03/2022 - Create Query
13/04/2022 - Add Voucher Start and End figures
26/09/2022 - Update to ensure that ONLY vouchers are obtained/displayed
*********************************************************************************/
WITH Voucher_Data as (
  SELECT * FROM liberator_permit_voucher
  WHERE import_Date = (Select MAX(import_date) from liberator_permit_voucher)),

Permit_Voucher as (
   SELECT * FROM liberator_permit_fta  
   WHERE import_Date = (Select MAX(import_date) from liberator_permit_fta)
   AND lower(permit_type) like '%voucher%'),

E_Voucher_Sessions as (
   Select evoucherorderid, count(*) as NoofBookings, 
   sum(numberofevouchersinsession) as numberofevouchersinsession
   FROM liberator_permit_evouchersession
   WHERE import_Date = (Select MAX(import_date) from liberator_permit_evouchersession)
   GROUP BY evoucherorderid), 

Permit_Print as (
   SELECT
   Permit_reference, Issue_date as printed_date, printed_by,
   ROW_NUMBER() OVER ( PARTITION BY Permit_reference 
                                 ORDER BY Permit_reference, Issue_date) R0
   FROM liberator_permit_printing
   Where Import_Date = (Select MAX(Import_Date) from liberator_permit_printing))


SELECT 
   A.permit_reference as Voucher_Ref, B.street,permit_type, amount, uprn, 
   status,application_date, cpz, cpz_name,
   quantity , forename_of_applicant,surname_of_applicant, 
   email_address_of_applicant, A.associated_to_order,
   printed_date, printed_by, e_voucher,
   NoofBookings, numberofevouchersinsession,
   voucher_start_number, voucher_end_number,

   current_timestamp()                            as ImportDateTime,
   replace(cast(current_date() as string),'-','') as import_date,
    
   cast(Year(current_date) as string)    as import_year, 
   cast(month(current_date) as string)   as import_month, 
   cast(day(current_date) as string)     as import_day
   
FROM Permit_Voucher as A
LEFT JOIN Voucher_Data as B ON A.permit_reference = B.permit_reference
LEFT JOIN Permit_Print as C ON A.permit_reference = C.permit_reference AND R0 = 1
LEFT JOIN E_Voucher_Sessions as D ON A.permit_reference = D.evoucherorderid
WHERE surname_of_applicant != 'Test'


"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_permit_voucher": AmazonS3_node1648207907397,
        "liberator_permit_fta": AmazonS3_node1648208237020,
        "liberator_permit_printing": AmazonS3_node1648208633220,
        "liberator_permit_evouchersession": AmazonS3_node1649411092913,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Voucher_De_Normalised/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Voucher_De_Normalised",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
