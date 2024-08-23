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

# Script generated for node Amazon S3 - liberator-refined-zone - pcnfoidetails_pcn_foi_full
AmazonS3liberatorrefinedzonepcnfoidetails_pcn_foi_full_node1720713551944 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-refined-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="pcnfoidetails_pcn_foi_full", transformation_ctx="AmazonS3liberatorrefinedzonepcnfoidetails_pcn_foi_full_node1720713551944")

# Script generated for node SQL Query - PCNs DVLA response no address
SqlQuery0 = '''
/*
All VRMs with PCNs response from DVLA has no address still open and not due to be written off

Criteria:
All PCNs issued
and is not void 
and does not have a warning flag
and is not vda and pcn issue date before '2021-06-01'  or can be vda after pcn issue date '2021-05-31'
and has had a dvla_request
and has had a dvla_response
and registered_keeper_address is not null
and has not had a PCN cancelled date
and has not had a pcn_casecloseddate
and next progression stage not like 'WRITEOFF'

11/07/2024 - Created

*/

with no_resp_ceo as (
Select distinct vrm as vrm_ceo
,count(distinct pcn) as num_pcns_ceo 

--, LISTAGG(pcn, '   ') WITHIN GROUP (ORDER BY vrm) as vl_multi_pcns_ceo
 ,array_join( -- concat the array
  collect_list(distinct pcnfoidetails_pcn_foi_full.pcn), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_pcns_ceo

FROM pcnfoidetails_pcn_foi_full

WHERE pcnfoidetails_pcn_foi_full.import_date = (SELECT max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) 
and isvoid = 0
and warningflag  = 0
and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 

and dvla_request is not null
and dvla_response is not null
and registered_keeper_address = ''
and pcn_canx_date is null
and pcn_casecloseddate is null 
and upper(debttype) like 'CEO'
and upper(nextprogressionstage) not like 'WRITEOFF'

--and cast(pcnissuedate as date) > cast('2019-12-31' as date) and cast(pcnissuedate as date) < cast('2024-01-01' as date)--Parking Tickets issued between 01/01/2020 and 31/12/2023.

group by vrm
order by vrm_ceo
)
, no_resp_cctv as (
Select distinct vrm as vrm_cctv
,count(distinct pcn) as num_pcns_cctv  

--, LISTAGG(pcn, '   ') WITHIN GROUP (ORDER BY vrm) as vl_multi_pcns_cctv
 ,array_join( -- concat the array
  collect_list(distinct pcnfoidetails_pcn_foi_full.pcn), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_pcns_cctv

FROM pcnfoidetails_pcn_foi_full

WHERE pcnfoidetails_pcn_foi_full.import_date = (SELECT max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) 
and isvoid = 0
and warningflag  = 0
and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 

and dvla_request is not null
and dvla_response is not null
and registered_keeper_address = ''
and pcn_canx_date is null
and pcn_casecloseddate is null 
and upper(debttype) in ('CCTV MOVING TRAFFIC','CCTV STATIC','CCTV BUS LANE')
and upper(nextprogressionstage) not like 'WRITEOFF'

--and cast(pcnissuedate as date) > cast('2019-12-31' as date) and cast(pcnissuedate as date) < cast('2024-01-01' as date)--Parking Tickets issued between 01/01/2020 and 31/12/2023.

group by vrm_cctv
order by vrm_cctv
)

-- summary sent to DRT
Select distinct pcnfoidetails_pcn_foi_full.vrm 
,min(cast(substr(Cast(pcnissuedate as varchar(10)),1, 10) as date)) as min_pcnissuedate
,max(cast(substr(Cast(pcnissuedate as varchar(10)),1, 10) as date)) as max_pcnissuedate
,count(distinct pcn) as num_pcns_all  

--, LISTAGG(pcn, '   ') WITHIN GROUP (ORDER BY vrm) as vl_multi_pcns_all
 ,array_join( -- concat the array
  collect_list(distinct pcnfoidetails_pcn_foi_full.pcn), -- aggregate that collects the array of [code]
  ' | ' -- delimiter 
 ) as vl_multi_pcns_all

--CEO PCNs
,num_pcns_ceo 
,vl_multi_pcns_ceo

--CCTV PCNs
,num_pcns_cctv  
,vl_multi_pcns_cctv

/*Partitions*/
,   pcnfoidetails_pcn_foi_full.import_year
,	pcnfoidetails_pcn_foi_full.import_month
,	pcnfoidetails_pcn_foi_full.import_day
,	pcnfoidetails_pcn_foi_full.import_date

FROM pcnfoidetails_pcn_foi_full

left join no_resp_cctv on no_resp_cctv.vrm_cctv = pcnfoidetails_pcn_foi_full.vrm
left join no_resp_ceo on no_resp_ceo.vrm_ceo = pcnfoidetails_pcn_foi_full.vrm

WHERE pcnfoidetails_pcn_foi_full.import_date = (SELECT max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) 
and isvoid = 0
and warningflag  = 0
and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 

and dvla_request is not null
and dvla_response is not null
and registered_keeper_address = ''
and pcn_canx_date is null
and pcn_casecloseddate is null 
and upper(nextprogressionstage) not like 'WRITEOFF'

--and cast(pcnissuedate as date) > cast('2019-12-31' as date) and cast(pcnissuedate as date) < cast('2024-01-01' as date)--Parking Tickets issued between 01/01/2020 and 31/12/2023.

group by pcnfoidetails_pcn_foi_full.vrm
--CEO PCNs
,num_pcns_ceo 
,vl_multi_pcns_ceo

--CCTV PCNs
,num_pcns_cctv  
,vl_multi_pcns_cctv

/*Partitions*/
,   pcnfoidetails_pcn_foi_full.import_year
,	pcnfoidetails_pcn_foi_full.import_month
,	pcnfoidetails_pcn_foi_full.import_day
,	pcnfoidetails_pcn_foi_full.import_date

order by pcnfoidetails_pcn_foi_full.vrm
'''
SQLQueryPCNsDVLAresponsenoaddress_node1720713555172 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"pcnfoidetails_pcn_foi_full":AmazonS3liberatorrefinedzonepcnfoidetails_pcn_foi_full_node1720713551944}, transformation_ctx = "SQLQueryPCNsDVLAresponsenoaddress_node1720713555172")

# Script generated for node Amazon S3 - parking_pcn_dvla_response_no_address
AmazonS3parking_pcn_dvla_response_no_address_node1720713560381 = glueContext.getSink(path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_pcn_dvla_response_no_address/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=["import_year", "import_month", "import_day", "import_date"], enableUpdateCatalog=True, transformation_ctx="AmazonS3parking_pcn_dvla_response_no_address_node1720713560381")
AmazonS3parking_pcn_dvla_response_no_address_node1720713560381.setCatalogInfo(catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",catalogTableName="parking_pcn_dvla_response_no_address")
AmazonS3parking_pcn_dvla_response_no_address_node1720713560381.setFormat("glueparquet", compression="snappy")
AmazonS3parking_pcn_dvla_response_no_address_node1720713560381.writeFrame(SQLQueryPCNsDVLAresponsenoaddress_node1720713555172)
job.commit()
