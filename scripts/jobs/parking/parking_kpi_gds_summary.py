import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame


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
        database="dataplatform-stg-liberator-raw-zone",
        table_name="liberator_pcn_ic",
        transformation_ctx="AmazonS3Liberator_pcn_ic_node1631812698045",
    )
)

# Script generated for node S3 bucket - pcnfoidetails_pcn_foi_full
S3bucketpcnfoidetails_pcn_foi_full_node1 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-stg-liberator-refined-zone",
        table_name="pcnfoidetails_pcn_foi_full",
        transformation_ctx="S3bucketpcnfoidetails_pcn_foi_full_node1",
    )
)

# Script generated for node Amazon S3 - liberator_pcn_tickets
AmazonS3liberator_pcn_tickets_node1637153316033 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-stg-liberator-raw-zone",
        table_name="liberator_pcn_tickets",
        transformation_ctx="AmazonS3liberator_pcn_tickets_node1637153316033",
    )
)

# Script generated for node ApplyMapping
SqlQuery0 = """
-- PCN GDS summary with disputes
/*17/11/2021 Added With regkep for field registered_keeper_address to pick up from original table liberator_pcn_tickets as from pcnfoidetails_pcn_foi_full cannot be resolved*/

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
,regkep as(select ticketserialnumber,registered_keeper_address,current_ticket_address,import_timestamp,import_year,import_month,import_day,import_date from liberator_pcn_tickets
WHERE liberator_pcn_tickets.import_date = (SELECT max(liberator_pcn_tickets.import_date) from liberator_pcn_tickets)
)

select
concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01')    AS IssueMonthYear
,cast(concat(Cast(extract(year from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month) as varchar(4)),'-',cast(extract(month from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month)as varchar(2)), '-01') as Date)    AS Dispute_kpi_MonthYear
--,cast(concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') as date) as monthyearissue
--,to_date(Substr(pcnissuedate, 1,7), 'Y-m') as month_year_pcnissuedate 
--,cast(Substr(pcnissuedate, 1,7) as date) as month_year_pcnissue_date
,	zone
,   (Case When zone like 'Estates' Then usrn Else zone End) as r_zone
,	usrn
,	contraventioncode
,	contraventionsuffix
,	holdreason
,	bailiff
,	eta_appealgrounds
,	eta_outcome
,	pcnfoidetails_pcn_foi_full.import_year
,	pcnfoidetails_pcn_foi_full.import_month
,	pcnfoidetails_pcn_foi_full.import_day
,	pcnfoidetails_pcn_foi_full.import_date -- import_date
--,   current_timestamp() as ImportDateTime

,count(*) as PCNs_Records
,Count (pcn_canx_date) as Num_Cancelled
,Count (pcn_casecloseddate) as Num_closed
,Sum(Case When pcn_canx_date is not null Then 1 Else 0 End) as Flag_PCN_CANCELLED
,count(regkep.registered_keeper_address) as num_reg_keep
,count(regkep.current_ticket_address) as num_curr_add

-- Flag registered_keeper_address or current address  registered_keeper_address
,Sum(Case When regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' ' or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' 'Then 0 Else 1 End) as Flag_address
,Sum(Case When regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' '  Then 1 Else 0 End) as Flag_address_null
,Sum(Case When regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' ' Then 0 Else 1 End) as Flag_reg_keeper_address
,Sum(Case When regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' '  Then 0 Else 1 End) as Flag_current_address
,Sum(Case When regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' ' Then 1 Else 0 End) as Flag_reg_keeper_address_null
,Sum(Case When regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' '  Then 1 Else 0 End) as Flag_current_address_null

-- ceo error flag by pcn type
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error
,Sum(Case When ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error
,Sum(Case When ((debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error
,Sum(Case When ((zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error

-- CEO error flag Without VOID VDA or warningflag
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_errorWO
,Sum(Case When ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%')  and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_errorWO
,Sum(Case When ((debttype like 'CCTV%') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ((debttype like 'CCTV%') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_errorWO
,Sum(Case When ((zone like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ( (zone like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_errorWO
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_errorWO

-- ceo error flag by pcn types with VDA
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error_vda
,Sum(Case When ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error_vda
,Sum(Case When ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error_vda
,Sum(Case When ((zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle')  and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error_vda
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and (cancellationreason like '%CEO failed%' or cancellationreason like '%CEO issued%' or cancellationreason like '%CEO recorded%' or cancellationreason like '%Info recorded in Electronic notes wrong/Inconsistent%' or cancellationreason like '%No Electronic notes made%' or cancellationreason like '%No proof served/Issued correctly%' or cancellationreason like '%Photos if taken do not support PCN if challenged%' or cancellationreason like 'PCN Issued to exempted vehicle') and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error_vda

-- PCNs kpi by pcn types for CEO Error
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0)  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0)  and cast(pcnissuedate as date) > cast('2021-06-30' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error_pcn
,Sum(Case When ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error_pcn
,Sum(Case When ((debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error_pcn
,Sum(Case When ((zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error_pcn
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error_pcn

-- PCNs kpi by pcn types for CEO Error with VDA
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0)  and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvoid = 0) and (warningflag  = 0)  and cast(pcnissuedate as date) > cast('2021-06-30' as date))  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_ceo_error_pcn_vda
,Sum(Case When ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ((zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date)) Then 1 Else 0 End) as Flag_kpi_Estates_ceo_error_pcn_vda
,Sum(Case When ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ((debttype like 'CCTV%')  and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_CCTV_ceo_error_pcn_vda
,Sum(Case When ((zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date) ) or ( (zone like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_Car_Parks_ceo_error_pcn_vda
,Sum(Case When ((debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) < cast('2021-07-01' as date)) or ( (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvoid = 0) and (warningflag  = 0) and cast(pcnissuedate as date) > cast('2021-06-30' as date) ) Then 1 Else 0 End) as Flag_kpi_onstreet_ceo_error_pcn_vda

,Sum(CASE When Lib_Payment_Received != '0' Then 1 Else 0 END) as Flag_PCN_PAYMENT
,Count(distinct pcn) as PCNs
,CAST(SUM(cast(lib_initial_debt_amount as double)) as decimal(11,2)) as Total_lib_initial_debt_amount
,CAST(SUM(cast(lib_payment_received as double)) as decimal(11,2)) as Total_lib_payment_received
,CAST(SUM(cast(lib_write_off_amount as double)) as decimal(11,2)) as Total_lib_write_off_amount
,CAST(SUM(cast(lib_payment_void as double)) as decimal(11,2)) as Total_lib_payment_void

-- KPI PCNs Paid by PCN type
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_paid
,Sum(Case When (zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_Estates_paid
,Sum(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_CCTV_paid

,Sum(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_Car_Parks_paid
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' Then 1 Else 0 End) as Flag_kpi_onstreet_paid

-- Paid with address by pcn type
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks_paid_address

,Sum(Case When (zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_Estates_paid_address
,Sum(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_CCTV_paid_address

,Sum(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_Car_Parks_paid_address
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Lib_Payment_Received != '0' and (regkep.registered_keeper_address is null or regkep.registered_keeper_address = '' or regkep.registered_keeper_address = ' '  or regkep.current_ticket_address is null or regkep.current_ticket_address = '' or regkep.current_ticket_address  = ' ' )  Then 1 Else 0 End) as Flag_kpi_onstreet_paid_address



-- Disputed pcns and by pcn type
,count(distinct Disputes.ticketserialnumber) as TotalpcnDisputed
,count(Disputes.ticketserialnumber) as TotalDisputed
/*,COUNT (distinct if (isvda = 0 and isvoid = 0 and warningflag  = 0, Disputes.ticketserialnumber
            )) as Dispute_pcn_Total 
,COUNT (if (isvda = 0 and isvoid = 0 and warningflag  = 0, Disputes.ticketserialnumber
            )) as Dispute_Total 
 */
 
,COUNT(DISTINCT(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) Flag_kpi_onstreet_carparks_disputes
,COUNT(DISTINCT(Case When (zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) Flag_kpi_Estates_disputes
,COUNT(DISTINCT(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flag_kpi_CCTV_disputes

,COUNT(DISTINCT(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flag_kpi_Car_Parks_disputes
,COUNT(DISTINCT(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) and Disputes.ticketserialnumber is not null  Then Disputes.ticketserialnumber End) ) as Flag_kpi_onstreet_disputes

--PCN Calculation include Where code warningflag = 0 and isvda = 0 and isvoid = 0. No Warnings NO VDA and No voided PCNs
--) and (cast(isvda as varchar) like '0') and (cast(isvoid as varchar) like '0') and (cast(warningflag as varchar) like '0')
--and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)

-- PCNs kpi by pcn types
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') ) and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)  Then 1 Else 0 End) as Flag_kpi_onstreet_carparks
,Sum(Case When (zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 1 Else 0 End) as Flag_kpi_Estates
,Sum(Case When (debttype like 'CCTV%')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 1 Else 0 End) as Flag_kpi_CCTV

,Sum(Case When (zone like 'Car Parks')  and (isvda = 0) and (isvoid = 0) and (warningflag  = 0) Then 1 Else 0 End) as Flag_kpi_Car_Parks
,Sum(Case When (debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks') and (isvda = 0) and (isvoid = 0) and (warningflag  = 0)  Then 1 Else 0 End) as Flag_kpi_onstreet

,Sum(Case When (isvda = 1) or (isvoid = 1) or (warningflag  = 1) Then 1 Else 0 End) as Flag_total_vda_void_warning

,Sum(Case When zone like 'Estates' or street_location like '%Estate%' OR usrn like 'Z%' Then 1 Else 0 End) as Flag_pi_Estates
,Sum(Case When zone like 'Car Parks' Then 1 Else 0 End) as Flag_pi_Car_Parks
,Sum(Case When debttype like 'CCTV%' Then 1 Else 0 End) as Flag_pi_CCTV
,Sum(Case When debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') or zone not like 'Car Parks'  Then 1 Else 0 End) as Flag_pi_onstreet
,Sum(Case When debttype not like 'CCTV%' or (zone not like 'Estates' or street_location not like '%Estate%' OR usrn not like 'Z%') Then 1 Else 0 End) as Flag_pi_onstreet_carparks

,Sum(Case When debttype like 'CEO' Then 1 Else 0 End) as Flag_debttype_CEO
,Sum(Case When debttype like 'CCTV Moving traffic' Then 1 Else 0 End) as Flag_debttype_CCTV_Moving_traffic
,Sum(Case When debttype like 'CCTV static' Then 1 Else 0 End) as Flag_debttype_CCTV_static
,Sum(Case When debttype like 'CCTV Bus Lane' Then 1 Else 0 End) as Flag_debttype_CCTV_Bus_Lane
,Sum(Case When debttype like 'Manual_Tickets' Then 1 Else 0 End) as Flag_debttype_Manual_Tickets

-- pcns not in kpi
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
WHERE pcnfoidetails_pcn_foi_full.import_date = (SELECT max(pcnfoidetails_pcn_foi_full.import_date) from pcnfoidetails_pcn_foi_full) and pcnissuedate > current_date - interval '34' month  --Last 36 months from todays date
group by concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01')
,cast(concat(Cast(extract(year from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month) as varchar(4)),'-',cast(extract(month from pcnfoidetails_pcn_foi_full.pcnissuedate + interval '3' month)as varchar(2)), '-01') as Date)
--,cast(concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') as date)
--,to_date(Substr(pcnissuedate, 1,7), 'Y-m')
--,cast(Substr(pcnissuedate, 1,7) as date)
,	zone
,   (Case When zone like 'Estates' Then usrn Else zone End)
,	usrn
,	contraventioncode
,	contraventionsuffix
,	holdreason
,	bailiff
,	eta_appealgrounds
,	eta_outcome
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
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-stg-refined-zone/parking/liberator/parking_kpi_gds_summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-stg-liberator-refined-zone",
    catalogTableName="parking_kpi_gds_summary",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
