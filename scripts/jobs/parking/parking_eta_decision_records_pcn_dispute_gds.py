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

# Script generated for node Amazon S3 - Liberator_pcn_ic
AmazonS3Liberator_pcn_ic_node1631812698045 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-raw-zone",
        table_name="liberator_pcn_ic",
        transformation_ctx="AmazonS3Liberator_pcn_ic_node1631812698045",
    )
)

# Script generated for node S3 bucket - pcnfoidetails_pcn_foi_full
S3bucketpcnfoidetails_pcn_foi_full_node1 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-refined-zone",
        table_name="pcnfoidetails_pcn_foi_full",
        transformation_ctx="S3bucketpcnfoidetails_pcn_foi_full_node1",
    )
)

# Script generated for node Amazon S3 - liberator_pcn_tickets
AmazonS3liberator_pcn_tickets_node1637153316033 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-"+environment+"-liberator-raw-zone",
        table_name="liberator_pcn_tickets",
        transformation_ctx="AmazonS3liberator_pcn_tickets_node1637153316033",
    )
)

# Script generated for node Amazon S3 - parking-raw-zone - eta_decision_records
AmazonS3parkingrawzoneeta_decision_records_node1645806323578 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="eta_decision_records",
    transformation_ctx="AmazonS3parkingrawzoneeta_decision_records_node1645806323578",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*23/03/2022 - created feed
07/04/2022 - added field for pcn stacking/grouping if pcn disputed/eta or not - added flage for HQ records as 'HQ_SiDEM_PCN' - updated join to match pcns with end special chars
*/

With er as (
SELECT case_reference, name ,pcn as er_pcn ,hearing_type ,case_status ,decision_i_e_dnc_appeal_allowed_appeal_rejected ,review_flag ,reporting_period ,month_year ,import_datetime as er_import_datetime ,import_timestamp as er_import_timestamp ,import_year as er_import_year ,import_month as er_import_month ,import_day as er_import_day ,import_date as er_import_date  FROM eta_decision_records 
where import_date = (SELECT max(import_date) FROM eta_decision_records )
)
,eta_recs as (
select pcn as etar_pcn--, Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Rejected','Appeal Refused') then 'REJECTED' when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Allowed','appeal Allowed') then 'ALLOWED' when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('DNC','dnc') then 'DNC' when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal with Direction','Direction') then 'DIRECTION' else upper(decision_i_e_dnc_appeal_allowed_appeal_rejected) end as etar_decision
 
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Rejected','Appeal Refused') then 1 else 0 end) as appeal_rejected
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Allowed','appeal Allowed') then 1 else 0 end) as appeal_allowed
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('DNC','dnc') then 1 else 0 end) as appeal_dnc
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal with Direction','Direction') then 1 else 0 end) as appeal_with_direction

FROM eta_decision_records  where eta_decision_records.import_date =(select max(eta_decision_records.import_date) FROM eta_decision_records) 
group by pcn , Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Rejected','Appeal Refused') then 'REJECTED' when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Allowed','appeal Allowed') then 'ALLOWED' when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('DNC','dnc') then 'DNC' when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal with Direction','Direction') then 'DIRECTION' else upper(decision_i_e_dnc_appeal_allowed_appeal_rejected) end order by pcn
)
,Disputes as (
SELECT distinct
     liberator_pcn_ic.ticketserialnumber
     ,count(distinct ticketserialnumber) as TotalpcnDisputed
,count(ticketserialnumber) as TotalDisputed
/*--       liberator_pcn_ic.Serviceable,
     cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)         as date_received,
     cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date) as response_generated_at,
     concat(substr(Cast(liberator_pcn_ic.date_received as varchar(10)),1, 7), '-01') as MonthYear,
     concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') as response_MonthYear,
  date_diff('day', cast(substr(liberator_pcn_ic.date_received, 1, 10) as date), cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date))  as ResponseDays*/
  ,  import_date as dispute_import_date

from liberator_pcn_ic

where liberator_pcn_ic.import_Date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic) 
AND liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != ''
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND liberator_pcn_ic.Serviceable IN ('Challenges','Key worker','Removals','TOL','Charge certificate','Representations')
group by liberator_pcn_ic.ticketserialnumber,  import_date

)
,pcn as (
SELECT * FROM pcnfoidetails_pcn_foi_full where import_date = (SELECT max(import_date) FROM pcnfoidetails_pcn_foi_full)
)
Select distinct 
(Case When zone like 'Estates' Then usrn when upper(substr(er.er_pcn, 1, 2)) ='HQ'then 'HQ_SiDEM_PCN' Else zone End) as r_zone
,Case
     When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' then 'onstreet'  
     When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) then 'Estates'
     When debttype like 'CCTV%'  then 'CCTV'
     When zone like 'Car Parks'  then 'Car Parks'
     when upper(substr(er.er_pcn, 1, 2)) ='HQ'then 'HQ_SiDEM_PCN'
 else debttype End as pcn_type
/* LTN Camera/location list as of 15/03/2022 - https://docs.google.com/spreadsheets/d/12_QqvToXPAMMLRMUQpQtwJg9gRZR0vMs_LQghhdwiYw*/
, (case When street_location = 'Allen Road' then 'YB1052 - Allen Road' 
When street_location = 'Ashenden Road junction of Glyn Road' then 'LW2205 - Ashenden Road' 
When street_location = 'Barnabas Road JCT Berger Road' then 'LW2204 - Barnabas Road' 
When street_location = 'Barnabas Road JCT Oriel Road' then 'LW2204 - Barnabas Road' 
When street_location = 'Benthal Road' then 'LW2206 - Benthal Road' 
When street_location = 'Bouverie Road junction of Stoke Newington Church Street' then 'LW2593 - Bouverie Road' 
When street_location = 'Clissold Crescent' then 'LW2397 - Clissold Crescent' 
When street_location = 'Cremer Street' then 'LW2041 - Cremer Street' 
When street_location = 'Downs Road' then 'LW2389 - Downs Road' 
When street_location = 'Elsdale Street' then 'LW2393 - Elsdale Street' 
When street_location = 'Gore Road junction of Lauriston Road.' then 'LW2078 - Gore Road' 
When street_location = 'Hyde Road' then 'LW2208 - Hyde Road' 
When street_location = 'Hyde Road JCT Northport Street' then 'LW2208 - Hyde Road' 
When street_location = 'Lee Street junction of Stean Street' then 'LW1535 - Lee Street' 
When street_location = 'Loddiges Road jct Frampton Park Road' then 'LW1051 - Loddiges Road' 
When street_location = 'Lordship Road junction of Lordship Terrace' then 'LW2590 - Lordship Road' 
When street_location = 'Maury Road junction of Evering Road' then 'LW2390 - Maury Road' 
When street_location = 'Mead Place' then 'LW2395 - Mead Place' 
When street_location = 'Meeson Street junction of Kingsmead Way' then 'LW2079 - Meeson Street' 
When street_location = 'Mount Pleasant Lane' then 'LW2391 - Mount Pleasant Lane' 
When street_location = 'Nevill Road junction of Barbauld Road' then 'LW2595 - Nevill Road/ Barbauld Road' 
When street_location = 'Nevill Road junction of Osterley Road' then 'LW0633 - Nevill Road (Osterley Road)' 
When street_location = 'Neville Road junction of Osterley Road' then 'LW0633 - Nevill Road (Osterley Road)' 
When street_location = 'Oldfield Road (E)' then 'LW2596 - Oldfield Road' 
When street_location = 'Oldfield Road junction of Kynaston Road' then 'LW2596 - Oldfield Road' 
When street_location = 'Pitfield Street (F)' then 'LW2207 - Pitfield Street' 
When street_location = 'Pitfield Street JCT Hemsworth Street' then 'LW2207 - Pitfield Street' 
When street_location = 'Powell Road junction of Kenninghall Road' then 'LW1691 - Powell Road (Kenninghall Road)' 
When street_location = 'Shepherdess Walk' then 'LW2076 - Shepherdess Walk' 
When street_location = 'Shore Place' then 'Mobile camera car - Shore Place'
When street_location = 'Stoke Newington Church Street junction of Lordship Road - Eastbound' then 'LW2591 - Stoke Newington Church Street eastbound' 
When street_location = 'Stoke Newington Church Street junction of Marton Road - Westbound' then 'LW2592 - Stoke Newington Church Street westbound' 
When street_location = 'Ufton Road junction of Downham Road' then 'LW2077 - Ufton Road' 
When street_location = 'Wayland Avenue' then 'LW2392 - Wayland Avenue' 
When street_location = 'Weymouth Terrace junction of Dunloe Street' then 'Mobile camera car - Weymouth Terrace' 
When street_location = 'Wilton Way junction of Greenwood Road' then 'LW1457 - Wilton Way' 
When street_location = 'Woodberry Grove junction of Rowley Gardens' then 'LW1457 - Woodberry Grove' 
When street_location = 'Woodberry Grove junction of Seven Sisters Road' then 'LW1457 - Woodberry Grove' 
When street_location = 'Yoakley Road junction of Stoke Newington Church Street' then 'LW2594 - Yoakley Road' else 'NOT current LTN Camera Location' end) as ltn_camera_location

,case when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 then 1 else 0 end as kpi_pcns

/*PCNs by Type with VDA's excluded before and included after 1st June 2021*/
  
,Case 
     When
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and isvoid = 0 
     and warningflag  = 0
     Then 1 Else 0 End as Flg_kpi_onstreet_carparks

,Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     Then 1 Else 0 End as Flg_kpi_Estates
     
,Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     Then 1 Else 0 End as Flg_kpi_CCTV

,Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0
     Then 1 Else 0 End as Flg_kpi_Car_Parks
     
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0  
     Then 1 Else 0 End as Flg_kpi_onstreet

-- Disputed pcns and by pcn type
,Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then 1 else 0 End Flg_kpi_onstreet_carparks_disputes 
,Case When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then 1 else 0 End Flag_kpi_Estates_disputes
,Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then 1 else 0 End as Flag_kpi_CCTV_disputes
,Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then 1 else 0 End as Flag_kpi_Car_Parks_disputes
,Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then 1 else 0 End  as Flg_kpi_onstreet_disputes
     
/*onstreet_carparks ETA Decisions*/
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End as Flg_decision_appeal_rejected_onstreet_carparks
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End as Flg_decision_appeal_allowed_onstreet_carparks
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End as Flg_decision_appeal_dnc_onstreet_carparks
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End as Flg_decision_appeal_with_direction_onstreet_carparks
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End as Flg_eta_decision_onstreet_carparks

/*Estates ETA Decisions*/
,Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End as Flg_decision_appeal_rejected_Estates
,Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End as Flg_decision_appeal_allowed_Estates
,Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End as Flg_decision_appeal_dnc_Estates
,Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End as Flg_decision_appeal_with_direction_Estates
,Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End as Flg_eta_decision_Estates


/*CCTV ETA Decisions*/
,Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End as Flg_decision_appeal_rejected_CCTV
,Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End as Flg_decision_appeal_allowed_CCTV
,Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End as Flg_decision_appeal_dnc_CCTV
,Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End as Flg_decision_appeal_with_direction_CCTV
,Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End as Flg_eta_decision_CCTV

/*Car_Parks ETA Decisions*/
,Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End as Flg_decision_appeal_rejected_Car_Parks
,Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End as Flg_decision_appeal_allowed_Car_Parks
,Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End as Flg_decision_appeal_dnc_Car_Parks
,Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End as Flg_decision_appeal_with_direction_Car_Parks
,Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End as Flg_eta_decision_Car_Parks


/*onstreet ETA Decisions*/
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End as Flg_decision_appeal_rejected_onstreet
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End as Flg_decision_appeal_allowed_onstreet
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End as Flg_decision_appeal_dnc_onstreet
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End as Flg_decision_appeal_with_direction_onstreet
,Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End as Flg_eta_decision_onstreet

/* All kpi ETA Decisions*/
,Case 
     When 
     ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End as Flg_decision_appeal_rejected_all_kpi
,Case 
     When 
     ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End as Flg_decision_appeal_allowed_all_kpi
,Case 
     When 
     ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End as Flg_decision_appeal_dnc_all_kpi
,Case 
     When 
     ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End as Flg_decision_appeal_with_direction_all_kpi
,Case 
     When 
     ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End as Flg_eta_decision_all_kpi
     
/*PCNs catergorised not eta or disputed for stacking*/
,case
when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and  ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is null then 'Not dispute or eta'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is not null then 'disputed'
when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction > 0 and Disputes.ticketserialnumber is null then 'eta with direction'
when   ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0  and eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0  and eta_recs.appeal_with_direction = 0 and  eta_recs.appeal_dnc > 0 and Disputes.ticketserialnumber is null then 'eta dnc'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_rejected = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0 and eta_recs.appeal_allowed > 0 and Disputes.ticketserialnumber is null then 'eta allowed'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0 and eta_recs.appeal_rejected > 0 and Disputes.ticketserialnumber is null then 'eta rejected'
when   ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_with_direction > 0 and Disputes.ticketserialnumber is not null  then 'disputed and eta with direction'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_dnc > 0 and Disputes.ticketserialnumber is not null then 'disputed and eta dnc'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_allowed > 0 and Disputes.ticketserialnumber is not null then 'disputed and eta allowed'
when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_rejected > 0 and Disputes.ticketserialnumber is not null then 'disputed and eta rejected'
else 'NOT KPI' end as kpi_pcn_dispute_eta_group

,case
when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and  ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is null then 'Y'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is not null then 'Y'
when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction > 0 and Disputes.ticketserialnumber is null then 'Y'
when   ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0  and eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0  and eta_recs.appeal_with_direction = 0 and  eta_recs.appeal_dnc > 0 and Disputes.ticketserialnumber is null then 'Y'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_rejected = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0 and eta_recs.appeal_allowed > 0 and Disputes.ticketserialnumber is null then 'Y'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0 and eta_recs.appeal_rejected > 0 and Disputes.ticketserialnumber is null then 'Y'
when   ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_with_direction > 0 and Disputes.ticketserialnumber is not null  then 'Y'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_dnc > 0 and Disputes.ticketserialnumber is not null then 'Y'
when  ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_allowed > 0 and Disputes.ticketserialnumber is not null then 'Y'
when ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and eta_recs.appeal_rejected > 0 and Disputes.ticketserialnumber is not null then 'Y'
else 'N' end as kpi_pcn_dispute_eta_flag

/*PCNs not eta or disputed*/
,case
when ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is null   Then 'Estates'
when debttype like 'CCTV%' and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is null Then 'CCTV'
when zone like 'Car Parks'  and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is null Then 'Car_Parks'
When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0  and warningflag  = 0 and ((eta_recs.appeal_rejected = 0 and eta_recs.appeal_allowed = 0 and eta_recs.appeal_dnc = 0 and eta_recs.appeal_with_direction = 0) or (eta_recs.appeal_rejected is null and eta_recs.appeal_allowed is null and eta_recs.appeal_dnc is null and eta_recs.appeal_with_direction is null)) and Disputes.ticketserialnumber is null Then 'onstreet'
/*disputed by kpi pcn type*/
when ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0) or (Disputes.ticketserialnumber is not null))  Then 'Estates - disputed_eta'
when debttype like 'CCTV%' and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0) or (Disputes.ticketserialnumber is not null))   Then 'CCTV - disputed_eta'
when zone like 'Car Parks'  and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0 and warningflag  = 0 and ((eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0) or (Disputes.ticketserialnumber is not null)) Then 'Car_Parks - disputed_eta'
When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) and isvoid = 0  and warningflag  = 0 and ((eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0) or (Disputes.ticketserialnumber is not null))  Then 'onstreet - disputed_eta'
else 'NOT KPI' end as kpi_pcn_not_dispute_eta_name

,*
from er 
left join eta_recs on substr(eta_recs.etar_pcn, 1, 10)  =  substr(er.er_pcn, 1, 10)
left join Disputes on Disputes.ticketserialnumber =  substr(er.er_pcn, 1, 10)
left join pcn on substr(er.er_pcn, 1, 10) = pcn.pcn
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_ic": AmazonS3Liberator_pcn_ic_node1631812698045,
        "pcnfoidetails_pcn_foi_full": S3bucketpcnfoidetails_pcn_foi_full_node1,
        "liberator_pcn_tickets": AmazonS3liberator_pcn_tickets_node1637153316033,
        "eta_decision_records": AmazonS3parkingrawzoneeta_decision_records_node1645806323578,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_eta_decision_records_pcn_dispute_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_eta_decision_records_pcn_dispute_gds",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
