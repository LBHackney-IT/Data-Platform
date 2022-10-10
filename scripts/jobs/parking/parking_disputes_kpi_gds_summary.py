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


# Script generated for node Amazon S3 - pcnfoidetails_pcn_foi_full
AmazonS3pcnfoidetails_pcn_foi_full_node1630000386155 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-refined-zone",
        table_name="pcnfoidetails_pcn_foi_full",
        transformation_ctx="AmazonS3pcnfoidetails_pcn_foi_full_node1630000386155",
    )
)

# Script generated for node Amazon S3 - Liberator_pcn_ic
AmazonS3Liberator_pcn_ic_node1628839657576 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-raw-zone",
        table_name="liberator_pcn_ic",
        transformation_ctx="AmazonS3Liberator_pcn_ic_node1628839657576",
    )
)

# Script generated for node ApplyMapping
SqlQuery0 = """



/**************************************************************************************************************
PCNs FOI with Disputes

Number Summary Disputes to parking PCNs for GDS

12/08/2021 - create the query for correspondence reps and appeals
26/08/2021 - updated for disputes
15/09/2021 - created updated version

****************************************************************************************************************/
WITH pcnfoi as (
select
cast(concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01')as date)    AS IssueMonthYear
 ,pcn
,pcnissuedate  
,pcnissuedate + interval '3' month as kpi_reporting_date
,cast(concat(Cast(extract(year from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month) as varchar(4)),'-',cast(extract(month from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month)as varchar(2)), '-01') as Date)    AS kpi_MonthYear

,(Case 
  When (zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 'Flag_kpi_Estates'
  When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 'Flag_kpi_CCTV'
  When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 'Flag_kpi_Car_Parks'
  When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)  Then 'Flag_kpi_onstreet'
  Else '0' End) as pcn_type
,(Case 
  When (zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 'Estates'
  When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 'CCTV'
  When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 'Car_Parks'
  When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)  Then 'OnStreet'
  Else '0' End) as pcn_type_name
  
  
FROM pcnfoidetails_pcn_foi_full
WHERE import_date = (SELECT max(import_date) from pcnfoidetails_pcn_foi_full)
and pcnissuedate > current_date - interval '36' month  --CAST(EVENT_TRIGGERED_DATE AS DATE)
and warningflag = 0 and isvda = 0  and isvoid = 0

order by concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') desc 
),
Disputes as (
SELECT distinct
     liberator_pcn_ic.ticketserialnumber,
     -- liberator_pcn_ic.Serviceable,
     cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)         as date_received,
     cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date) as response_generated_at,
     cast(concat(substr(Cast(liberator_pcn_ic.date_received as varchar(10)),1, 7), '-01') as date) as MonthYear,
     datediff( cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date), cast(substr(liberator_pcn_ic.date_received, 1, 10) as date) )  as ResponseDays,
    import_date 

from liberator_pcn_ic

where liberator_pcn_ic.import_date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic) 
AND liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != ''
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND liberator_pcn_ic.Serviceable IN ('Challenges','Key worker','Removals','TOL','Charge certificate','Representations')
  )

select issuemonthyear,kpi_MonthYear, pcn_type, pcn_type_name
, count (*) as TotalPCN_records, count(distinct pcn) as TotalPCNs, count(distinct ticketserialnumber) as TotalpcnDisputed, count(ticketserialnumber) as TotalDisputed
/*** Control Dates ***/       
    ,substr(Cast(current_date as varchar(10)),1, 4) as import_year,
    substr(Cast(current_date as varchar(10)),6, 2) as import_month,
    substr(Cast(current_date as varchar(10)),9, 4) as import_day,
    Cast(current_date as varchar(10))              as import_date

from pcnfoi
left join disputes on disputes.ticketserialnumber = pcnfoi.pcn

group by issuemonthyear, kpi_MonthYear, pcn_type, pcn_type_name
order by issuemonthyear desc

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_ic": AmazonS3Liberator_pcn_ic_node1628839657576,
        "pcnfoidetails_pcn_foi_full": AmazonS3pcnfoidetails_pcn_foi_full_node1630000386155,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_Disputes_KPI_GDS_Summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_Disputes_kpi_gds_summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
