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

# Script generated for node Amazon S3 - Liberator_pcn_ic
AmazonS3Liberator_pcn_ic_node1631812698045 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_pcn_ic",
        transformation_ctx="AmazonS3Liberator_pcn_ic_node1631812698045",
    )
)

# Script generated for node S3 bucket - pcnfoidetails_pcn_foi_full
S3bucketpcnfoidetails_pcn_foi_full_node1 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-refined-zone",
        table_name="pcnfoidetails_pcn_foi_full",
        transformation_ctx="S3bucketpcnfoidetails_pcn_foi_full_node1",
    )
)

# Script generated for node Amazon S3 - liberator_pcn_tickets
AmazonS3liberator_pcn_tickets_node1637153316033 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_pcn_tickets",
        transformation_ctx="AmazonS3liberator_pcn_tickets_node1637153316033",
    )
)

# Script generated for node Amazon S3 - liberator-raw-zone - liberator_pcn_audit
AmazonS3liberatorrawzoneliberator_pcn_audit_node1638297295740 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_audit",
    transformation_ctx="AmazonS3liberatorrawzoneliberator_pcn_audit_node1638297295740",
)

# Script generated for node Amazon S3 - parking-raw-zone - eta_decision_records
AmazonS3parkingrawzoneeta_decision_records_node1645806323578 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="eta_decision_records",
    transformation_ctx="AmazonS3parkingrawzoneeta_decision_records_node1645806323578",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
-- PCN GDS summary with location for FOI Dashboard
/*
17/11/2021 Added With regkep for field registered_keeper_address to pick up from original table liberator_pcn_tickets as from pcnfoidetails_pcn_foi_full cannot be resolved
30/11/2021 Updated/added PCN recovery by PCN type
20/01/2022 added additional field street_location comment out fields (whereonlocation, holdreason, bailiff,	eta_appealgrounds, eta_outcome) increased to 51 mths from 34 mths about 98055 records
*/

With Disputes as (
SELECT distinct -- *,
     liberator_pcn_ic.ticketserialnumber,
--       liberator_pcn_ic.Serviceable,
     cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)         as date_received,
     cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date) as response_generated_at,
     concat(substr(Cast(liberator_pcn_ic.date_received as varchar(10)),1, 7), '-01') as MonthYear,
     concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') as response_MonthYear,
  datediff( cast(substr(liberator_pcn_ic.date_received, 1, 10) as date), cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date))  as ResponseDays,
  import_date

from liberator_pcn_ic

where liberator_pcn_ic.import_Date = (Select MAX(liberator_pcn_ic.import_date) from liberator_pcn_ic) 
AND liberator_pcn_ic.date_received != '' AND liberator_pcn_ic.response_generated_at != ''
AND length(liberator_pcn_ic.ticketserialnumber) = 10
AND liberator_pcn_ic.Serviceable IN ('Challenges','Key worker','Removals','TOL','Charge certificate','Representations')
)
,eta_recs as (
select pcn as etar_pcn, 
sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Rejected','Appeal Refused') then 1 else 0 end) as appeal_rejected
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal Allowed','appeal Allowed') then 1 else 0 end) as appeal_allowed
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('DNC','dnc') then 1 else 0 end) as appeal_dnc
,sum(Case when decision_i_e_dnc_appeal_allowed_appeal_rejected in ('Appeal with Direction','Direction') then 1 else 0 end) as appeal_with_direction

FROM eta_decision_records  where eta_decision_records.import_date =(select max(eta_decision_records.import_date) FROM eta_decision_records) 
group by pcn order by pcn
)

,regkep as(select ticketserialnumber,registered_keeper_address,current_ticket_address,import_timestamp,import_year,import_month,import_day,import_date from liberator_pcn_tickets
WHERE liberator_pcn_tickets.import_date = (SELECT max(liberator_pcn_tickets.import_date) from liberator_pcn_tickets)
)
,pcn_audit as(
SELECT distinct(audit_message),ticket_ref, liberator_pcn_audit.import_date, 1 as flag_write_off FROM liberator_pcn_audit
where liberator_pcn_audit.import_date = (SELECT max(liberator_pcn_audit.import_date) from liberator_pcn_audit) 
and audit_message in ('Debt write-off request raised: 3 or more VQ5 without keeper','Debt write-off request raised: 455+ day old warrant','Debt write-off request raised: DVLA address','Debt write-off request raised: Foreign vehicle','Debt write-off request raised: No seemingly valid postcode','Debt write-off request raised: Scottish address')
order by ticket_ref desc
)
, pcn_recovery_reason as (select distinct pcn as cancel_pcn, cancellationgroup as cancellation_group, cancellationreason as cancellation_reason, pcnfoidetails_pcn_foi_full.import_date, 1 as flag_cancel_reason  FROM pcnfoidetails_pcn_foi_full
WHERE pcnfoidetails_pcn_foi_full.import_date = (SELECT max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) and cancellationgroup in ('Bailiff','CANCELLED - VULNERABLE DEBTOR','Debt Recovery','Pre-debt','System','Write-off'))

select
concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01')    AS IssueMonthYear
,cast(concat(Cast(extract(year from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month) as varchar(4)),'-',cast(extract(month from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month)as varchar(2)), '-01') as Date)    AS Dispute_kpi_MonthYear
--,cast(concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') as date) as monthyearissue
--,to_date(Substr(pcnissuedate, 1,7), 'Y-m') as month_year_pcnissuedate 
--,cast(Substr(pcnissuedate, 1,7) as date) as month_year_pcnissue_date
,	zone
,   (Case When zone like 'Estates' Then usrn Else zone End) as r_zone
,	usrn
,   street_location
-- ,   whereonlocation
,	contraventioncode
,	contraventionsuffix
-- ,	holdreason
-- ,	bailiff
-- ,	eta_appealgrounds
-- ,	eta_outcome
,	pcnfoidetails_pcn_foi_full.import_year
,	pcnfoidetails_pcn_foi_full.import_month
,	pcnfoidetails_pcn_foi_full.import_day
,	pcnfoidetails_pcn_foi_full.import_date as importdate -- import_date
,   concat(pcnfoidetails_pcn_foi_full.import_year,pcnfoidetails_pcn_foi_full.import_month,pcnfoidetails_pcn_foi_full.import_day) as import_date
--,   current_timestamp() as ImportDateTime

,count(*) as PCNs_Records
,Count (pcn_canx_date) as Num_Cancelled
,Count (pcn_casecloseddate) as Num_closed
,Sum(Case When pcn_canx_date is not null Then 1 Else 0 End) as Flag_PCN_CANCELLED
,count(regkep.registered_keeper_address) as num_reg_keep
,count(regkep.current_ticket_address) as num_curr_add

-- Flag registered_keeper_address or current address  registered_keeper_address
,Sum(Case When regkep.registered_keeper_address != '' or regkep.current_ticket_address != '' Then 1 Else 0 End) as Flag_address
,Sum(Case When regkep.registered_keeper_address = '' or regkep.current_ticket_address = '' Then 1 Else 0 End) as Flag_address_null
,Sum(Case When regkep.registered_keeper_address != '' Then 1 Else 0 End) as Flag_reg_keeper_address
,Sum(Case When regkep.current_ticket_address != '' Then 1 Else 0 End) as Flag_current_address
,Sum(Case When regkep.registered_keeper_address = '' Then 1 Else 0 End) as Flag_reg_keeper_address_null
,Sum(Case When regkep.current_ticket_address = '' Then 1 Else 0 End) as Flag_current_address_null

-- CEO error All
,Sum(Case When (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvda = 0 and isvoid = 0 and warningflag  = 0 and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvoid = 0 and warningflag  = 0 and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flg_kpi_ceo_error
,Sum(Case When (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvda = 0 and isvoid = 0 and warningflag  = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvoid = 0 and warningflag  = 0 and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flg_kpi_ceo_error_pcn


-- ceo error flag by pcn type
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error
,Sum(Case When (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvda = 0 and isvoid = 0 and warningflag  = 0 and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvoid = 0 and warningflag  = 0 and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flg_kpi_onstreet_carparks_ceo_error

,Sum(Case When (((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error
,Sum(Case When ((debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error
,Sum(Case When ((zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error

,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error
,Sum(Case When (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and isvda = 0 and isvoid = 0 and warningflag  = 0 and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and isvoid = 0 and warningflag  = 0 and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flg_kpi_onstreet_ceo_error


-- CEO error flag Without VOID VDA or warningflag
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_errorWO
,Sum(Case When (((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%')  and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_errorWO
,Sum(Case When ((debttype like 'CCTV%') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ((debttype like 'CCTV%') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_errorWO
,Sum(Case When ((zone like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ( (zone like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_errorWO
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_errorWO

-- ceo error flag by pcn types with VDA
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error_vda
,Sum(Case When (((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error_vda
,Sum(Case When ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error_vda
,Sum(Case When ((zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error_vda
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like '%PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error_vda

-- PCNs kpi by pcn types for CEO Error
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0)  and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0)  and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error_pcn
,Sum(Case When (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvda = 0 and isvoid = 0 and warningflag  = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and isvoid = 0 and warningflag  = 0 and cast(pcnissuedate as date) > cast('2021-05-31' as date))  Then 1 Else 0 End) as Flg_kpi_onstreet_carparks_ceo_error_pcn

,Sum(Case When (((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-05-31' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error_pcn
,Sum(Case When ((debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error_pcn
,Sum(Case When ((zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-06-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error_pcn
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error_pcn
,Sum(Case When (debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and isvda = 0 and isvoid = 0 and warningflag  = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or ( debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and isvoid = 0 and warningflag  = 0 and cast(pcnissuedate as date) > cast('2021-05-31' as date) ) Then 1 Else 0 End) as Flg_kpi_onstreet_ceo_error_pcn

,Sum(CASE When Lib_Payment_Received != '0' Then 1 Else 0 END) as Flag_PCN_PAYMENT
,Count(distinct pcn) as PCNs
,CAST(SUM(cast(lib_initial_debt_amount as double)) as decimal(11,2)) as Total_lib_initial_debt_amount
,CAST(SUM(cast(lib_payment_received as double)) as decimal(11,2)) as Total_lib_payment_received
,CAST(SUM(cast(lib_write_off_amount as double)) as decimal(11,2)) as Total_lib_write_off_amount
,CAST(SUM(cast(lib_payment_void as double)) as decimal(11,2)) as Total_lib_payment_void

-- KPI PCNs Paid by PCN type
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_paid
,Sum(Case When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_Estates_paid
,Sum(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_CCTV_paid

,Sum(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_Car_Parks_paid
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_onstreet_paid

-- Paid with address by pcn type
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_paid_address

,Sum(Case When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_Estates_paid_address
,Sum(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_CCTV_paid_address

,Sum(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_Car_Parks_paid_address
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_onstreet_paid_address

-- PCN Recovery
/*PCN Recovered All*/
,sum(case 
          when Lib_Payment_Received != '0' 
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype like 'CCTV%'
     and (regkep.registered_keeper_address != '' or regkep.current_ticket_address != '')
then 1
     when Lib_Payment_Received != '0' 
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype not like 'CCTV%'
  then 1 else 0 end) as pcn_recovered

,sum(case 
    when ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype like 'CCTV%'
     and (regkep.registered_keeper_address != '' or regkep.current_ticket_address != '')
then 1
     when 
      ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype not like 'CCTV%'
  then 1 else 0 end) as pcn_recovered_can
  
/*PCN Recovered by Type - CCTV*/

,sum(case 
          when Lib_Payment_Received != '0'
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype like 'CCTV%'
     and (regkep.registered_keeper_address != '' or regkep.current_ticket_address != '')
  then 1 else 0 end) as pcn_recovered_cctv

,sum(case 
    when 
     ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype like 'CCTV%'
     and (regkep.registered_keeper_address != '' or regkep.current_ticket_address != '')
  then 1 else 0 end) as pcn_recovered_can_cctv

/*PCN Recovered by Type - Estates*/

,sum(case 
     when Lib_Payment_Received != '0' 
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))
  then 1 else 0 end) as pcn_recovered_estates

,sum(case 
     when 
      ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%'))
  then 1 else 0 end) as pcn_recovered_can_estates

/*PCN Recovered by Type - Carparks*/

,sum(case 
     when Lib_Payment_Received != '0' 
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and (zone like 'Car Parks')
  then 1 else 0 end) as pcn_recovered_carparks

,sum(case 
     when 
      ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and (zone like 'Car Parks')
  then 1 else 0 end) as pcn_recovered_can_carparks


/*PCN Recovered by Type - onstreet*/

,sum(case 
     when Lib_Payment_Received != '0' 
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'
  then 1 else 0 end) as pcn_recovered_onstreet

,sum(case 
     when 
      ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'
  then 1 else 0 end) as pcn_recovered_can_onstreet


/*PCN Recovered by Type - carparks and onstreet*/
,sum(case 
     when Lib_Payment_Received != '0' 
     and ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%'
  then 1 else 0 end) as pcn_recovered_onstreet_carparks

,sum(case 
     when 
      ((pcn_canx_date is null and pcn_recovery_reason.cancellation_group is null and pcn_recovery_reason.cancellation_reason is null) or (pcn_canx_date is not null and pcn_recovery_reason.cancellation_group is not null and pcn_recovery_reason.cancellation_reason is not null))
     and isvoid = 0
     and warningflag  = 0
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%'
  then 1 else 0 end) as pcn_recovered_can_onstreet_carparks

/*PCNs by Type with VDA's excluded before and included after 1st June 2021*/
  
,Sum(Case 
     When
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) )
     and isvoid = 0 
     and warningflag  = 0
     Then 1 Else 0 End) as Flg_kpi_onstreet_carparks

,Sum(Case 
     When 
     ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     Then 1 Else 0 End) as Flg_kpi_Estates
     
,Sum(Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     Then 1 Else 0 End) as Flg_kpi_CCTV

,Sum(Case 
     When 
     zone like 'Car Parks'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0
     Then 1 Else 0 End) as Flg_kpi_Car_Parks
     
,Sum(Case 
     When 
     debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' 
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0  
     Then 1 Else 0 End) as Flg_kpi_onstreet



-- Disputed pcns and by pcn type
,count(distinct Disputes.ticketserialnumber) as TotalpcnDisputed
,count(Disputes.ticketserialnumber) as TotalDisputed
/*,COUNT (distinct if (isvda = 0 and isvoid = 0 and warningflag  = 0, Disputes.ticketserialnumber
            )) as Dispute_pcn_Total 
,COUNT (if (isvda = 0 and isvoid = 0 and warningflag  = 0, Disputes.ticketserialnumber
            )) as Dispute_Total 
 */

,COUNT(DISTINCT(Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) Flg_kpi_onstreet_carparks_disputes 
,COUNT(DISTINCT(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) Flag_kpi_onstreet_carparks_disputes
,COUNT(DISTINCT(Case When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) Flag_kpi_Estates_disputes
,COUNT(DISTINCT(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flag_kpi_CCTV_disputes

,COUNT(DISTINCT(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flag_kpi_Car_Parks_disputes
,COUNT(DISTINCT(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flag_kpi_onstreet_disputes
,COUNT(DISTINCT(Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks' and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flg_kpi_onstreet_disputes

/*ETA records with by PCN Type*/
,sum(eta_recs.appeal_rejected) as decision_appeal_rejected
,sum(eta_recs.appeal_allowed) as decision_appeal_allowed
,sum(eta_recs.appeal_dnc) as decision_appeal_dnc
,sum(eta_recs.appeal_with_direction) as decision_appeal_with_direction

,Sum(Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_rejected > 0
     Then eta_recs.appeal_rejected Else 0 End) as Flg_decision_appeal_rejected_CCTV
,Sum(Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_allowed  > 0
     Then eta_recs.appeal_allowed Else 0 End) as Flg_decision_appeal_allowed_CCTV
,Sum(Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_dnc > 0
     Then eta_recs.appeal_dnc Else 0 End) as Flg_decision_appeal_dnc_CCTV
,Sum(Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and eta_recs.appeal_with_direction > 0
     Then eta_recs.appeal_with_direction Else 0 End) as Flg_decision_appeal_with_direction_CCTV
,Sum(Case 
     When 
     debttype like 'CCTV%'  
     and ((isvda = 0 and cast(pcnissuedate as date) < cast('2021-06-01' as date)) or (cast(pcnissuedate as date) > cast('2021-05-31' as date)) ) 
     and isvoid = 0 
     and warningflag  = 0 
     and (eta_recs.appeal_rejected > 0 or eta_recs.appeal_allowed > 0 or eta_recs.appeal_dnc > 0 or eta_recs.appeal_with_direction > 0)
     Then (eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction ) Else 0 End) as Flg_eta_decision_CCTV


--PCN Calculation include Where code warningflag = 0 and isvda = 0 and isvoid = 0. No Warnings NO VDA and No voided PCNs
--) and (cast(isvda as varchar) like '0') and (cast(isvoid as varchar) like '0') and (cast(warningflag as varchar) like '0')
--and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)

-- PCNs kpi by pcn types
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks
,Sum(Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)  Then 1 Else 0 End) as Flg_kpi_onstreet_carparks
,Sum(Case When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 1 Else 0 End) as Flag_kpi_Estates
,Sum(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 1 Else 0 End) as Flag_kpi_CCTV

,Sum(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 1 Else 0 End) as Flag_kpi_Car_Parks


,Sum(Case When (isvda = 1) or (isvoid = 1) or (warningflag  = 1) Then 1 Else 0 End) as Flag_total_vda_void_warning

,Sum(Case When ((zone like 'Estates') or (street_location like '%Estate%') OR (usrn like 'Z%')) Then 1 Else 0 End) as Flag_pi_Estates
,Sum(Case When zone like 'Car Parks' Then 1 Else 0 End) as Flag_pi_Car_Parks
,Sum(Case When debttype like 'CCTV%' Then 1 Else 0 End) as Flag_pi_CCTV
,Sum(Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' and zone not like 'Car Parks'  Then 1 Else 0 End) as Flag_pi_onstreet
,Sum(Case When debttype not like 'CCTV%' and zone not like 'Estates' and street_location not like '%Estate%' and usrn not like 'Z%' Then 1 Else 0 End) as Flag_pi_onstreet_carparks

,Sum(Case When debttype like 'CEO' Then 1 Else 0 End) as Flag_debttype_CEO
,Sum(Case When debttype like 'CCTV Moving traffic' Then 1 Else 0 End) as Flag_debttype_CCTV_Moving_traffic
,Sum(Case When debttype like 'CCTV static' Then 1 Else 0 End) as Flag_debttype_CCTV_static
,Sum(Case When debttype like 'CCTV Bus Lane' Then 1 Else 0 End) as Flag_debttype_CCTV_Bus_Lane
,Sum(Case When debttype like 'Manual_Tickets' Then 1 Else 0 End) as Flag_debttype_Manual_Tickets

-- pcns not in kpi
,sum(case when cast(pcnissuedate as date) > cast('2021-08-09' as date) then 1 else 0 end) as af_ten_aug_PCN_issue
,sum(case when cast(pcnissuedate as date) < cast('2021-08-10' as date) then 1 else 0 end) as bf_ten_aug_PCN_issue
,sum(case when cast(pcnissuedate as date) > cast('2021-05-31' as date) then 1 else 0 end) as af_first_jun_PCN_issue
,sum(case when cast(pcnissuedate as date) < cast('2021-06-01' as date) then 1 else 0 end) as bf_first_jun_PCN_issue

,Sum(Case When isvda = 1 Then 1 Else 0 End) as Flag_total_isvda
,Sum(Case When isvoid = 1 Then 1 Else 0 End) as Flag_total_isvoid
,Sum(Case When cast(isremoval as INTEGER) = 1  Then 1 Else 0 End) as Flag_total_isremoval
,Sum(Case When warningflag = 1  Then 1 Else 0 End) as Flag_total_warningflag

,Sum(Case When progressionstage like 'discount' Then 1 Else 0 End) as Flag_progressionstage_discount
,Sum(Case When progressionstage like 'postalgrace' Then 1 Else 0 End) as Flag_progressionstage_postalgrace
,Sum(Case When progressionstage like 'waitdvla' Then 1 Else 0 End) as Flag_progressionstage_waitdvla
,Sum(Case When progressionstage like 'readytoprint' Then 1 Else 0 End) as Flag_progressionstage_readytoprint
,Sum(Case When progressionstage like 'nto' Then 1 Else 0 End) as Flag_progressionstage_nto
,Sum(Case When progressionstage like 'full' Then 1 Else 0 End) as Flag_progressionstage_full
,Sum(Case When progressionstage like 'cc' Then 1 Else 0 End) as Flag_progressionstage_cc
,Sum(Case When progressionstage like 'nfa' Then 1 Else 0 End) as Flag_progressionstage_nfa
,Sum(Case When progressionstage like 'warningnoticesent' Then 1 Else 0 End) as Flag_progressionstage_warningnoticesent
,Sum(Case When progressionstage like 'en' Then 1 Else 0 End) as Flag_progressionstage_en
,Sum(Case When progressionstage like 'foreigncollection' Then 1 Else 0 End) as Flag_progressionstage_foreigncollection
,Sum(Case When progressionstage like 'nodr' Then 1 Else 0 End) as Flag_progressionstage_nodr
,Sum(Case When progressionstage like 'predebt' Then 1 Else 0 End) as Flag_progressionstage_predebt
,Sum(Case When progressionstage like 'nodrr' Then 1 Else 0 End) as Flag_progressionstage_nodrr
,Sum(Case When progressionstage like 'warrant' Then 1 Else 0 End) as Flag_progressionstage_warrant
,Sum(Case When progressionstage like 'warr' Then 1 Else 0 End) as Flag_progressionstage_warr
,Sum(Case When progressionstage like 'pre-debt' Then 1 Else 0 End) as Flag_progressionstage_pre_debt


,Sum(Case When nto_printed is not null Then 1 Else 0 End) as Flag_nto_printed
,Sum(Case When appeal_accepted is not null Then 1 Else 0 End) as Flag_appeal_accepted
,Sum(Case When arrived_in_pound is not null Then 1 Else 0 End) as Flag_arrived_in_pound
,Sum(Case When cancellation_reversed is not null Then 1 Else 0 End) as Flag_cancellation_reversed
,Sum(Case When cc_printed is not null Then 1 Else 0 End) as Flag_cc_printed
,Sum(Case When drr is not null Then 1 Else 0 End) as Flag_drr
,Sum(Case When en_printed is not null Then 1 Else 0 End) as Flag_en_printed
,Sum(Case When hold_released is not null Then 1 Else 0 End) as Flag_hold_released
,Sum(Case When dvla_response is not null Then 1 Else 0 End) as Flag_dvla_response
,Sum(Case When dvla_request is not null Then 1 Else 0 End) as Flag_dvla_request
,Sum(Case When full_rate_uplift is not null Then 1 Else 0 End) as Flag_full_rate_uplift
,Sum(Case When hold_until is not null Then 1 Else 0 End) as Flag_hold_until
,Sum(Case When lifted_at is not null Then 1 Else 0 End) as Flag_lifted_at
,Sum(Case When lifted_by is not null Then 1 Else 0 End) as Flag_lifted_by
,Sum(Case When loaded is not null Then 1 Else 0 End) as Flag_loaded
,Sum(Case When nor_sent is not null Then 1 Else 0 End) as Flag_nor_sent
,Sum(Case When notice_held is not null Then 1 Else 0 End) as Flag_notice_held
,Sum(Case When ofr_printed is not null Then 1 Else 0 End) as Flag_ofr_printed
,Sum(Case When pcn_printed is not null Then 1 Else 0 End) as Flag_pcn_printed
,Sum(Case When reissue_nto_requested is not null Then 1 Else 0 End) as Flag_reissue_nto_requested
,Sum(Case When reissue_pcn is not null Then 1 Else 0 End) as Flag_reissue_pcn
,Sum(Case When set_back_to_pre_cc_stage is not null Then 1 Else 0 End) as Flag_set_back_to_pre_cc_stage
,Sum(Case When vehicle_released_for_auction is not null Then 1 Else 0 End) as Flag_vehicle_released_for_auction
,Sum(Case When warrant_issued is not null Then 1 Else 0 End) as Flag_warrant_issued
,Sum(Case When warrant_redistributed is not null Then 1 Else 0 End) as Flag_warrant_redistributed
,Sum(Case When warrant_request_granted is not null Then 1 Else 0 End) as Flag_warrant_request_granted
,Sum(Case When ad_hoc_vq4_request is not null Then 1 Else 0 End) as Flag_ad_hoc_vq4_request
,Sum(Case When paper_vq5_received is not null Then 1 Else 0 End) as Flag_paper_vq5_received
,Sum(Case When pcn_extracted_for_buslane is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_buslane
,Sum(Case When pcn_extracted_for_pre_debt is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_pre_debt
,Sum(Case When pcn_extracted_for_collection is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_collection
,Sum(Case When pcn_extracted_for_drr is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_drr
,Sum(Case When pcn_extracted_for_cc is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_cc
,Sum(Case When pcn_extracted_for_nto is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_nto
,Sum(Case When pcn_extracted_for_print is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_print
,Sum(Case When warning_notice_extracted_for_print is not null Then 1 Else 0 End) as Flag_warning_notice_extracted_for_print
,Sum(Case When pcn_extracted_for_ofr is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_ofr
,Sum(Case When pcn_extracted_for_warrant_request is not null Then 1 Else 0 End) as Flag_pcn_extracted_for_warrant_request
,Sum(Case When pre_debt_new_debtor_details is not null Then 1 Else 0 End) as Flag_pre_debt_new_debtor_details

FROM pcnfoidetails_pcn_foi_full
left join Disputes on Disputes.ticketserialnumber = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = Disputes.import_date
left join regkep on regkep.ticketserialnumber = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = regkep.import_date
left join pcn_audit on pcn_audit.ticket_ref = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = pcn_audit.import_date
left join pcn_recovery_reason on pcn_recovery_reason.cancel_pcn = pcnfoidetails_pcn_foi_full.pcn and pcnfoidetails_pcn_foi_full.import_date = pcn_recovery_reason.import_date
left join eta_recs on eta_recs.etar_pcn  = pcnfoidetails_pcn_foi_full.pcn

WHERE pcnfoidetails_pcn_foi_full.import_date = (SELECT max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) and pcnissuedate > current_date - interval '51' month  --Last 36 months from todays date
group by concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01')
,cast(concat(Cast(extract(year from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month) as varchar(4)),'-',cast(extract(month from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month)as varchar(2)), '-01') as Date)
--,cast(concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') as date)
--,to_date(Substr(pcnissuedate, 1,7), 'Y-m')
--,cast(Substr(pcnissuedate, 1,7) as date)
,	zone
,   (Case When zone like 'Estates' Then usrn Else zone End)
,	usrn
,   street_location
-- ,   whereonlocation
,	contraventioncode
,	contraventionsuffix
-- ,	holdreason
-- ,	bailiff
-- ,	eta_appealgrounds
-- ,	eta_outcome
,	pcnfoidetails_pcn_foi_full.import_year
,	pcnfoidetails_pcn_foi_full.import_month
,	pcnfoidetails_pcn_foi_full.import_day
,	pcnfoidetails_pcn_foi_full.import_date -- import_date
--,   current_timestamp() as ImportDateTime
order by concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') desc
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_ic": AmazonS3Liberator_pcn_ic_node1631812698045,
        "pcnfoidetails_pcn_foi_full": S3bucketpcnfoidetails_pcn_foi_full_node1,
        "liberator_pcn_tickets": AmazonS3liberator_pcn_tickets_node1637153316033,
        "liberator_pcn_audit": AmazonS3liberatorrawzoneliberator_pcn_audit_node1638297295740,
        "eta_decision_records": AmazonS3parkingrawzoneeta_decision_records_node1645806323578,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_foi_pcn_gds_summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_foi_pcn_gds_summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
