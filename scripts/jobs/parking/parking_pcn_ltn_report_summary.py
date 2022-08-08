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

# Script generated for node ApplyMapping
SqlQuery0 = """
/*************************************************************************************************************************
Parking_PCN_LTN_Report_Summary

The SQL builds the PCN Low Traffic Network figures, for use with the answering of the LTN FOI's

12/07/2021 - Create SQL. 
*************************************************************************************************************************/
SELECT concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01')    AS IssueMonthYear,
       street_location,
       COUNT(distinct pcn)                                              AS PCNs_Issued,
       CAST(SUM(cast(lib_payment_received as double)) as decimal(11,2)) AS Total_Amount_Paid,

       
       current_timestamp() as ImportDateTime,
    
       replace(cast(current_date() as string),'-','') as import_date,
    
       -- Add the Import date
       cast(Year(current_date) as string)  as import_year, 
       cast(month(current_date) as string) as import_month,
       cast(day(current_date) as string)   as import_day

FROM pcnfoidetails_pcn_foi_full as A
WHERE warningflag = 0 and isvda = 0 and isvoid = 0 AND
vrm != 'T123EST' AND contraventioncode = '52' AND
street_location IN ('Allen Road',
'Ashenden Road junction of Glyn Road',
'Barnabas Road JCT Berger Road','Barnabas Road JCT Oriel Road',
'Brooke Road (E)',
'Brooke Road junction of Evering Road',
'Dove Row',
'Gore Road junction of Lauriston Road.',
'Hyde Road',
'Hyde Road JCT Northport Street',
'Lee Street junction of Stean Street',
'Maury Road junction of Evering Road',
'Meeson Street junction of Kingsmead Way',
'Nevill Road junction of Osterley Road',
'Neville Road junction of Osterley Road',
'Pitfield Street (F)',
'Pitfield Street JCT Hemsworth Street',
'Powell Road junction of Kenninghall Road',
'Pritchard`s Road',
'Pritchards Road',
'Richmond Road junction of Greenwood Road',
'Shepherdess Walk',
'Ufton Road junction of Downham Road', 'Wilton Way junction of Greenwood Road') 

GROUP BY  concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01'), street_location, import_date, import_day, import_month, import_year
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"pcnfoidetails_pcn_foi_full": AmazonS3_node1625732651466},
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_PCN_LTN_Report_Summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_PCN_LTN_Report_Summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
