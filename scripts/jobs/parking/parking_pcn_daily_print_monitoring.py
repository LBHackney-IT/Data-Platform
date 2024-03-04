import sys
import time
from typing import Dict
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, create_pushdown_predicate

def sparkSqlQuery(glue_context: GlueContext, query: str, mapping: Dict[str, DynamicFrame], transformation_ctx: str) -> DynamicFrame:
    """
    Executes a SQL query using Spark SQL and returns the result as a DynamicFrame.
    """
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = glue_context.spark_session.sql(query)
    return DynamicFrame.fromDF(result, glue_context, transformation_ctx)

start_time = time.time()
# Parsing script arguments
args = getResolvedOptions(sys.argv, ["JOB_NAME"])

# Initialize Spark and Glue contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Retrieve environment variable
environment = get_glue_env_var("environment")
print(f"preparing the environment variable {(time.time() - start_time)/60:.2f} minutes")


# Script generated for node raw_zone_liberator_pcn_tickets
# Load data from Glue Catalog tables
start_time = time.time()
raw_zone_liberator_pcn_tickets_node1666105465609 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-raw-zone",
        table_name="liberator_pcn_tickets",
        transformation_ctx="raw_zone_liberator_pcn_tickets_node1666105465609",
        push_down_predicate=create_pushdown_predicate("import_date",7)
    )
)
print(f"loading raw_zone_liberator_pcn_tickets_node1666105465609 {(time.time() - start_time)/60:.2f} minutes")


# Script generated for node raw_zone_liberator_pcn_audit
# Load data from Glue Catalog tables
start_time = time.time()
raw_zone_liberator_pcn_audit_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_pcn_audit",
    transformation_ctx="raw_zone_liberator_pcn_audit_node1",
    push_down_predicate=create_pushdown_predicate("import_date",7)
)
print(f"loading raw_zone_liberator_pcn_audit_node1 {(time.time() - start_time)/60:.2f} minutes")


# Script generated for node ApplyMapping
# Define and execute SQL query on loaded data
start_time = time.time()
SqlQuery0 = """
/*
Takes data from Liberator raw zone for PCN print monitoring for the previous day of the import_date

18/10/2022 - Created query
*/
with pcn_audit as (select 
ticket_ref as pcna_ticket_ref
,audit_row as pcna_audit_row
,user_name as pcna_user_name
,audit_message as pcna_audit_message
,record_date_time as pcna_record_date_time
,event_date_time as pcna_event_date_time
,cast(event_date_time as date) as event_date
,record_created as pcna_record_created

,import_timestamp as pcna_import_timestamp
,import_year as pcna_import_year
,import_month as pcna_import_month
,import_date as pcna_import_date
,cast(concat(import_year,'-',import_month,'-',import_day) as date) as  pcna_importdate

FROM liberator_pcn_audit where 
import_date = (select max (import_date) FROM liberator_pcn_audit ) 

and cast(event_date_time as date) = cast(concat(import_year,'-',import_month,'-',import_day) as date)  - interval '1' day 

and (
upper(audit_message) LIKE 'WARNING NOTICE EXTRACTED%' or
upper(audit_message) LIKE 'PCN EXTRACTED FOR PRINT' or
upper(audit_message) LIKE 'HHTPCN PRINTED%' or
upper(audit_message) LIKE 'PCN PRINTED%'  or

upper(audit_message) LIKE 'BUSLANE PCN EXTRACTED FOR ENFORCEMENT NOTICE%' or
upper(audit_message) LIKE 'EN PRINTED%'  or

upper(audit_message) LIKE 'PCN EXTRACTED FOR NTO%'  or
upper(audit_message) LIKE 'NTO PRINTED%' or

upper(audit_message) LIKE 'PCN EXTRACTED FOR CC%' or
upper(audit_message) LIKE 'CC PRINTED%'  or

upper(audit_message) LIKE 'OFR PRINTED%' or
upper(audit_message) LIKE 'PCN EXTRACTED FOR OFR%'
)
)

SELECT 
case
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'CCTV Bus Lane' then 'BLPCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'BUSLANE PCN EXTRACTED FOR ENFORCEMENT NOTICE%' and tickettype like 'CCTV Bus Lane' then 'EN'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'CCTV Bus Lane' then 'BL CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'CCTV Bus Lane' then 'BL OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'CCTV Moving traffic' then 'MT PCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'WARNING NOTICE EXTRACTED FOR PRINT%' and tickettype like 'CCTV Moving traffic' then 'MT W'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'CCTV Moving traffic' then 'MT CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'CCTV Moving traffic' then 'MT OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'CCTV static' then 'ST PCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'CCTV static' then 'ST CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'CCTV static' then 'ST OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'WARNING NOTICE EXTRACTED FOR PRINT%' and tickettype like 'CCTV static' then 'ST W'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR NTO%' and tickettype like 'hht' then 'NTO'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'hht' then 'CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'hht' then 'OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'hht' then 'HHT PCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN PRINTED%' and tickettype like 'CCTV Bus Lane' then 'BLPCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'EN PRINTED %' and tickettype like 'CCTV Bus Lane' then 'EN'
when upper(pcn_audit.pcna_audit_message) LIKE 'CC PRINTED %' and tickettype like 'CCTV Bus Lane' then 'BL CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'OFR PRINTED%' and tickettype like 'CCTV Bus Lane' then 'BL OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN PRINTED%' and tickettype like 'CCTV Moving traffic' then 'MT PCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'CC PRINTED %' and tickettype like 'CCTV Moving traffic' then 'MT CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'OFR PRINTED%' and tickettype like 'CCTV Moving traffic' then 'MT OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'PCN PRINTED%' and tickettype like 'CCTV static' then 'ST PCN'
when upper(pcn_audit.pcna_audit_message) LIKE 'CC PRINTED %' and tickettype like 'CCTV static' then 'ST CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'OFR PRINTED%' and tickettype like 'CCTV static' then 'ST OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'NTO PRINTED%' and tickettype like 'hht' then 'NTO'
when upper(pcn_audit.pcna_audit_message) LIKE 'CC PRINTED %' and tickettype like 'hht' then 'CC'
when upper(pcn_audit.pcna_audit_message) LIKE 'OFR PRINTED%' and tickettype like 'hht' then 'OFR'
when upper(pcn_audit.pcna_audit_message) LIKE 'HHTPCN PRINTED%' and tickettype like 'hht' then 'HHT PCN'
else upper(pcn_audit.pcna_audit_message) end as print_file_type
,*
FROM pcn_audit 
left join liberator_pcn_tickets on pcna_ticket_ref = ticketserialnumber and pcna_import_date = liberator_pcn_tickets.import_date


"""

# Execute the SQL query to do the transformation
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_audit": raw_zone_liberator_pcn_audit_node1,
        "liberator_pcn_tickets": raw_zone_liberator_pcn_tickets_node1666105465609,
    },
    transformation_ctx="ApplyMapping_node2",
)
print(f"executing ApplyMapping_node2 {(time.time() - start_time)/60:.2f} minutes")

# Script generated for node S3 bucket
# Instantiate a Glue sink for writing data to an S3 bucket
start_time = time.time()
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_pcn_daily_print_monitoring/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)

# Set the catalog information for the data being written. This includes specifying the database and table in the Glue Data Catalog.
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_pcn_daily_print_monitoring",
)
# Set the format of the data files (Parquet) to be written to the S3 bucket.
S3bucket_node3.setFormat("glueparquet")

# Write the data frame to the S3 bucket using the configurations defined above.
# Convert DynamicFrame to DataFrame and coalesce into a single partition
# based on my review the each day's data is less than 400kb with a single parquet file
coalescedDF = ApplyMapping_node2.toDF().coalesce(1)
# Convert back to DynamicFrame
coalescedDynamicFrame = DynamicFrame.fromDF(coalescedDF, glueContext, "coalescedDF")
# Write the coalesced DynamicFrame to the S3 bucket
S3bucket_node3.writeFrame(coalescedDynamicFrame)

print(f"writing S3bucket_node3 {(time.time() - start_time)/60:.2f} minutes")
# Commit the job to finalize the write operation and ensure that all resources are properly released.
job.commit()

