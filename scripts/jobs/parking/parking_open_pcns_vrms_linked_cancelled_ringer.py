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

# Script generated for node Amazon S3 - Refined - pcnfoidetails_pcn_foi_full
AmazonS3Refinedpcnfoidetails_pcn_foi_full_node1708021619806 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3Refinedpcnfoidetails_pcn_foi_full_node1708021619806",
)

# Script generated for node SQL Query
SqlQuery0 = """
/*Open PCNs linked to VRMs cancelled due to being a Ringer or Clone
Created: 15/02/2024

*/
With cancelled_vrm as (
Select distinct vrm as canx_vrm 
from pcnfoidetails_pcn_foi_full where import_date = (select max(import_date) from pcnfoidetails_pcn_foi_full) and (upper(cancellationgroup) like '%RINGER%' or upper(cancellationreason) like '%RINGER%') 
)
Select cancelled_vrm.*, concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') as MonthYear 
,progressionstage ,debttype ,pcn ,pcnissuedate ,pcnissuedatetime ,street_location ,whereonlocation ,zone ,usrn ,contraventioncode ,contraventionsuffix  ,vrm ,vehiclemake ,vehiclemodel ,vehiclecolour,corresp_dispute_flag ,registered_keeper_address ,current_ticket_address

/*Registered extracted post codes*/
,case when length(regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') ) = 0 or regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') is null or  regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like '' or  regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like ' '  then 'No Address' else regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})')  end
as reg_add_extracted_post_code

/*Current extracted post codes*/
,case when length(regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') ) = 0 or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') is null or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like '' or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like ' ' then 'No Address' else regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') end
as curr_add_extracted_post_code
,bailiff

/*for partiion*/

,replace(cast(current_date() as string),'-','') as import_date
,cast(Year(current_date) as string)    as import_year 
,cast(month(current_date) as string)   as import_month 
,cast(day(current_date) as string)     as import_day

from pcnfoidetails_pcn_foi_full 
left join cancelled_vrm on cancelled_vrm.canx_vrm = pcnfoidetails_pcn_foi_full.vrm

where pcnfoidetails_pcn_foi_full.import_date = (select max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) and (pcnfoidetails_pcn_foi_full.pcn_canx_date is null and pcnfoidetails_pcn_foi_full.pcn_casecloseddate is null) and cancelled_vrm.canx_vrm is not null and pcnfoidetails_pcn_foi_full.warningflag = 0
order by cancelled_vrm.canx_vrm ,progressionstage ,debttype ,pcnissuedatetime desc ,pcn ,street_location
"""
SQLQuery_node1708021630710 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "pcnfoidetails_pcn_foi_full": AmazonS3Refinedpcnfoidetails_pcn_foi_full_node1708021619806
    },
    transformation_ctx="SQLQuery_node1708021630710",
)

# Script generated for node Amazon S3
AmazonS3_node1708021659577 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_open_pcns_vrms_linked_cancelled_ringer/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1708021659577",
)
AmazonS3_node1708021659577.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_open_pcns_vrms_linked_cancelled_ringer",
)
AmazonS3_node1708021659577.setFormat("glueparquet", compression="snappy")
AmazonS3_node1708021659577.writeFrame(SQLQuery_node1708021630710)
job.commit()
