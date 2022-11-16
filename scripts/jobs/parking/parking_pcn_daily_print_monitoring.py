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

# Script generated for node raw_zone_liberator_pcn_tickets
raw_zone_liberator_pcn_tickets_node1666105465609 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-raw-zone",
        table_name="liberator_pcn_tickets",
        transformation_ctx="raw_zone_liberator_pcn_tickets_node1666105465609",
    )
)

# Script generated for node raw_zone_liberator_pcn_audit
raw_zone_liberator_pcn_audit_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_pcn_audit",
    transformation_ctx="raw_zone_liberator_pcn_audit_node1",
)

# Script generated for node ApplyMapping
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
when upper(audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'CCTV Bus Lane' then 'BLPCN'
when upper(audit_message) LIKE 'BUSLANE PCN EXTRACTED FOR ENFORCEMENT NOTICE%' and tickettype like 'CCTV Bus Lane' then 'EN'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'CCTV Bus Lane' then 'BL CC'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'CCTV Bus Lane' then 'BL OFR'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'CCTV Moving traffic' then 'MT PCN'
when upper(audit_message) LIKE 'WARNING NOTICE EXTRACTED FOR PRINT%' and tickettype like 'CCTV Moving traffic' then 'MT W'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'CCTV Moving traffic' then 'MT CC'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'CCTV Moving traffic' then 'MT OFR'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'CCTV static' then 'ST PCN'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'CCTV static' then 'ST CC'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'CCTV static' then 'ST OFR'
when upper(audit_message) LIKE 'WARNING NOTICE EXTRACTED FOR PRINT%' and tickettype like 'CCTV static' then 'ST W'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR NTO%' and tickettype like 'hht' then 'NTO'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR CC%' and tickettype like 'hht' then 'CC'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR OFR%' and tickettype like 'hht' then 'OFR'
when upper(audit_message) LIKE 'PCN EXTRACTED FOR PRINT%' and tickettype like 'hht' then 'HHT PCN'
when upper(audit_message) LIKE 'PCN PRINTED%' and tickettype like 'CCTV Bus Lane' then 'BLPCN'
when upper(audit_message) LIKE 'EN PRINTED %' and tickettype like 'CCTV Bus Lane' then 'EN'
when upper(audit_message) LIKE 'CC PRINTED %' and tickettype like 'CCTV Bus Lane' then 'BL CC'
when upper(audit_message) LIKE 'OFR PRINTED%' and tickettype like 'CCTV Bus Lane' then 'BL OFR'
when upper(audit_message) LIKE 'PCN PRINTED%' and tickettype like 'CCTV Moving traffic' then 'MT PCN'
when upper(audit_message) LIKE 'CC PRINTED %' and tickettype like 'CCTV Moving traffic' then 'MT CC'
when upper(audit_message) LIKE 'OFR PRINTED%' and tickettype like 'CCTV Moving traffic' then 'MT OFR'
when upper(audit_message) LIKE 'PCN PRINTED%' and tickettype like 'CCTV static' then 'ST PCN'
when upper(audit_message) LIKE 'CC PRINTED %' and tickettype like 'CCTV static' then 'ST CC'
when upper(audit_message) LIKE 'OFR PRINTED%' and tickettype like 'CCTV static' then 'ST OFR'
when upper(audit_message) LIKE 'NTO PRINTED%' and tickettype like 'hht' then 'NTO'
when upper(audit_message) LIKE 'CC PRINTED %' and tickettype like 'hht' then 'CC'
when upper(audit_message) LIKE 'OFR PRINTED%' and tickettype like 'hht' then 'OFR'
when upper(audit_message) LIKE 'HHTPCN PRINTED%' and tickettype like 'hht' then 'HHT PCN'
else upper(audit_message) end as print_file_type
,*
FROM pcn_audit 
left join liberator_pcn_tickets on pcna_ticket_ref = ticketserialnumber and pcna_import_date = liberator_pcn_tickets.import_date


"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_audit": raw_zone_liberator_pcn_audit_node1,
        "liberator_pcn_tickets": raw_zone_liberator_pcn_tickets_node1666105465609,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_pcn_daily_print_monitoring/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_pcn_daily_print_monitoring",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
