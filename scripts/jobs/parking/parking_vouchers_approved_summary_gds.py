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

# Script generated for node S3 bucket - Raw - liberator_permit_fta
S3bucketRawliberator_permit_fta_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_fta",
    transformation_ctx="S3bucketRawliberator_permit_fta_node1",
)

# Script generated for node Amazon S3 - raw - liberator_permit_renewals
AmazonS3rawliberator_permit_renewals_node1643219669907 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_permit_renewals",
        transformation_ctx="AmazonS3rawliberator_permit_renewals_node1643219669907",
    )
)

# Script generated for node Amazon S3 - refined - dc_liberator_latest_permit_status
AmazonS3refineddc_liberator_latest_permit_status_node1643219673143 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="dc_liberator_latest_permit_status",
    transformation_ctx="AmazonS3refineddc_liberator_latest_permit_status_node1643219673143",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/* Vouchers from Permits FTA by Month Year FY CPZ and CPZ name
20220126 - Created*/

SELECT
cast(concat(substr(Cast(liberator_permit_fta.application_date as varchar(10)),1, 7), '-01') as date) as month_year_application_date
-- cast(to_date(Substr(liberator_permit_fta.application_date, 1,7), '%Y-%m') as date) as month_year_application_date

,Case
when cast(liberator_permit_fta.application_date as varchar(10)) like '2028-03-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2028-02-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2028-01-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-12-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-11-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-10-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-09-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-08-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-07-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-06-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-05-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-04-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-03-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-02-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-01-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-12-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-11-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-10-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-09-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-08-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-07-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-06-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-05-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-04-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-03-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-02-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-01-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-12-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-11-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-10-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-09-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-08-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-07-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-06-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-05-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-04-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-03-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-02-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-01-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-12-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-11-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-10-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-09-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-08-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-07-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-06-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-05-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-04-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-03-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-02-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-01-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-12-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-11-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-10-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-09-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-08-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-07-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-06-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-05-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-04-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-03-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-02-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-01-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-12-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-11-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-10-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-09-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-08-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-07-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-06-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-05-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-04-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-03-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-02-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-01-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-12-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-11-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-10-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-09-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-08-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-07-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-06-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-05-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-04-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-03-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-02-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-01-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-12-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-11-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-10-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-09-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-08-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-07-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-06-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-05-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-04-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-03-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-02-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-01-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-12-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-11-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-10-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-09-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-08-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-07-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-06-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-05-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-04-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-03-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-02-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-01-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-12-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-11-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-10-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-09-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-08-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-07-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-06-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-05-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-04-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-03-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-02-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-01-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-12-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-11-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-10-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-09-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-08-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-07-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-06-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-05-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-04-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-03-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-02-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-01-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-12-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-11-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-10-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-09-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-08-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-07-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-06-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-05-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-04-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-03-%'  THEN '2015'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-02-%'  THEN '2015'
else '1900'
end as fy
-- 	permit_reference
 ,	cpz
 ,	cpz_name
,case when cpz !='' and cpz_name != '' then concat(cpz,' - ', cpz_name)
when cpz !='' and cpz_name = '' then concat(cpz)
when cpz ='' and cpz_name != '' then concat(cpz_name)
else 'NONE'
end as zone_name

,to_date(cast(concat(substr(Cast(liberator_permit_fta.application_date as varchar(10)),1, 7), '-01') as date), 'MMM YYYY') as mon_yr_app_date
-- ,to_date(cast(to_date(Substr(liberator_permit_fta.application_date, 1,7), '%Y-%m') as date), 'MMM YYYY') as mon_yr_app_date

--fta and renewal

,if(
	(liberator_permit_fta.status = 'Renewed' or liberator_permit_fta.status = 'Approved' or liberator_permit_fta.status = 'ORDER_APPROVED' or liberator_permit_fta.status = 'PENDING_VRM_CHANGE' or liberator_permit_fta.status = 'Created' or liberator_permit_fta.status = 'PENDING_ADDR_CHANGE' or liberator_permit_fta.status = 'PAYMENT_RECEIVED'),1
,if(
	(liberator_permit_renewals.renewal_payment_status = 'Renewed' or liberator_permit_renewals.renewal_payment_status = 'Approved' or liberator_permit_renewals.renewal_payment_status = 'ORDER_APPROVED' or liberator_permit_renewals.renewal_payment_status = 'PENDING_VRM_CHANGE' or liberator_permit_renewals.renewal_payment_status = 'Created' or liberator_permit_renewals.renewal_payment_status = 'PENDING_ADDR_CHANGE' or liberator_permit_renewals.renewal_payment_status = 'PAYMENT_RECEIVED')
 , 1, 0)) as approved_status_flag
 
,liberator_permit_fta.permit_type as voucher_period
,substr(liberator_permit_fta.permit_reference,1,3) as PermitType
,case
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYA' then 'All zone'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYG' then 'Companion Badge'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYB' then 'Business'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYD' then 'Doctor'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYP' then 'Estate resident'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYH' then 'Health and social care'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYR' then 'Residents'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYL' then 'Leisure Centre Permit'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYE' then 'All Zone Business Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYF' then 'Film Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYJ' then 'Health and Social Care Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYQ' then 'Estate Visitor Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYV' then 'Resident Visitor Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) ='HYN' then 'Dispensation'
 when liberator_permit_fta.permit_reference ='HY50300' then 'Dispensation'
 else substr(liberator_permit_fta.permit_reference,1,3)
 end as permit_type_Category

,Case when substr(liberator_permit_fta.permit_reference,1,3) ='HYE' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYF' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYQ' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYV' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYJ' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYN' then 'Dispensation'
when liberator_permit_fta.permit_reference ='HY50300' then 'Dispensation'
when substr(liberator_permit_fta.permit_reference,1,3)='HYS' then 'Suspension' else 'Permit'
end as product_category

,case when (substr(liberator_permit_fta.permit_reference,1,3) ='HYE' or 
 substr(liberator_permit_fta.permit_reference,1,3)='HYF'or
substr(liberator_permit_fta.permit_reference,1,3)='HYQ' or
substr(liberator_permit_fta.permit_reference,1,3)='HYV' or
substr(liberator_permit_fta.permit_reference,1,3)='HYJ' ) and
 liberator_permit_fta.e_voucher ='E' then 'eVoucher'
when (substr(liberator_permit_fta.permit_reference,1,3) ='HYE' or 
 substr(liberator_permit_fta.permit_reference,1,3)='HYF'or
substr(liberator_permit_fta.permit_reference,1,3)='HYQ' or
substr(liberator_permit_fta.permit_reference,1,3)='HYV' or
substr(liberator_permit_fta.permit_reference,1,3)='HYJ' ) and
 liberator_permit_fta.e_voucher <> 'E' then 'Paper Voucher' else 'Not Voucher' end as voucher_type_category
,   liberator_permit_fta.import_year
,	liberator_permit_fta.import_month
,	liberator_permit_fta.import_day
,	liberator_permit_fta.import_date

-- Counters

,count(concat(liberator_permit_fta.application_date,liberator_permit_fta.email_address_of_applicant)) as num_unique_transaction_ref
,count(distinct concat(liberator_permit_fta.application_date,liberator_permit_fta.email_address_of_applicant)) as num_distinct_unique_transaction_ref


,count(liberator_permit_fta.email_address_of_applicant) as num_email_address_ref
,count(distinct liberator_permit_fta.email_address_of_applicant) as num_distinct_email_address_ref

,sum(cast(liberator_permit_fta.quantity as decimal(9,0))) as total_quantity
 
FROM liberator_permit_fta 

LEFT JOIN liberator_permit_renewals ON liberator_permit_renewals.permit_reference = liberator_permit_fta.permit_reference AND liberator_permit_renewals.import_date = liberator_permit_fta.import_date

left JOIN dc_liberator_latest_permit_status on dc_liberator_latest_permit_status.permit_referece = liberator_permit_fta.permit_reference and dc_liberator_latest_permit_status.import_date = liberator_permit_fta.import_date

--LEFT JOIN dc_liberator_permit_llpg_street_records on (dc_liberator_permit_llpg_street_records.sr_uprn = liberator_permit_fta.uprn) and dc_liberator_permit_llpg_street_records.import_date = liberator_permit_fta.import_date
 
WHERE liberator_permit_fta.import_date = (SELECT MAX(liberator_permit_fta.import_date) FROM liberator_permit_fta) 

and if(
	(liberator_permit_fta.status = 'Renewed' or liberator_permit_fta.status = 'Approved' or liberator_permit_fta.status = 'ORDER_APPROVED' or liberator_permit_fta.status = 'PENDING_VRM_CHANGE' or liberator_permit_fta.status = 'Created' or liberator_permit_fta.status = 'PENDING_ADDR_CHANGE' or liberator_permit_fta.status = 'PAYMENT_RECEIVED'),1
,if(
	(liberator_permit_renewals.renewal_payment_status = 'Renewed' or liberator_permit_renewals.renewal_payment_status = 'Approved' or liberator_permit_renewals.renewal_payment_status = 'ORDER_APPROVED' or liberator_permit_renewals.renewal_payment_status = 'PENDING_VRM_CHANGE' or liberator_permit_renewals.renewal_payment_status = 'Created' or liberator_permit_renewals.renewal_payment_status = 'PENDING_ADDR_CHANGE' or liberator_permit_renewals.renewal_payment_status = 'PAYMENT_RECEIVED')
 , 1, 0))=1
-- and liberator_permit_fta.payment_location Not like '%Post%'
and (substr(liberator_permit_fta.permit_reference,1,3) ='HYE' or 
 substr(liberator_permit_fta.permit_reference,1,3)='HYF'or
substr(liberator_permit_fta.permit_reference,1,3)='HYQ' or
substr(liberator_permit_fta.permit_reference,1,3)='HYV' or
substr(liberator_permit_fta.permit_reference,1,3)='HYJ' )

group by
Case
when cast(liberator_permit_fta.application_date as varchar(10)) like '2028-03-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2028-02-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2028-01-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-12-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-11-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-10-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-09-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-08-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-07-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-06-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-05-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-04-%'  THEN '2027'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-03-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-02-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2027-01-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-12-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-11-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-10-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-09-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-08-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-07-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-06-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-05-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-04-%'  THEN '2026'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-03-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-02-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2026-01-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-12-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-11-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-10-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-09-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-08-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-07-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-06-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-05-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-04-%'  THEN '2025'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-03-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-02-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2025-01-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-12-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-11-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-10-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-09-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-08-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-07-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-06-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-05-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-04-%'  THEN '2024'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-03-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-02-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2024-01-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-12-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-11-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-10-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-09-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-08-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-07-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-06-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-05-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-04-%'  THEN '2023'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-03-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-02-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2023-01-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-12-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-11-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-10-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-09-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-08-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-07-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-06-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-05-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-04-%'  THEN '2022'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-03-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-02-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2022-01-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-12-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-11-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-10-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-09-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-08-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-07-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-06-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-05-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-04-%'  THEN '2021'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-03-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-02-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2021-01-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-12-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-11-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-10-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-09-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-08-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-07-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-06-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-05-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-04-%'  THEN '2020'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-03-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-02-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2020-01-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-12-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-11-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-10-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-09-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-08-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-07-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-06-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-05-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-04-%'  THEN '2019'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-03-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-02-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2019-01-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-12-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-11-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-10-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-09-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-08-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-07-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-06-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-05-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-04-%'  THEN '2018'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-03-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-02-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2018-01-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-12-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-11-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-10-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-09-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-08-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-07-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-06-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-05-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-04-%'  THEN '2017'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-03-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-02-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2017-01-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-12-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-11-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-10-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-09-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-08-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-07-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-06-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-05-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-04-%'  THEN '2016'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-03-%'  THEN '2015'
when cast(liberator_permit_fta.application_date as varchar(10)) like '2016-02-%'  THEN '2015'
else '1900' end
-- ,to_date(Substr(liberator_permit_fta.application_date, 1,7), '%Y-%m')
,cast(concat(substr(Cast(liberator_permit_fta.application_date as varchar(10)),1, 7), '-01') as date)
 ,	cpz
 ,	cpz_name
 ,case when cpz !='' and cpz_name != '' then concat(cpz,' - ', cpz_name)
when cpz !='' and cpz_name = '' then concat(cpz)
when cpz ='' and cpz_name != '' then concat(cpz_name)
else 'NONE' end
-- ,to_date(cast(to_date(Substr(liberator_permit_fta.application_date, 1,7), '%Y-%m') as date), 'MMM YYYY')
,to_date(cast(concat(substr(Cast(liberator_permit_fta.application_date as varchar(10)),1, 7), '-01') as date), 'MMM YYYY')

,if(
	(liberator_permit_fta.status = 'Renewed' or liberator_permit_fta.status = 'Approved' or liberator_permit_fta.status = 'ORDER_APPROVED' or liberator_permit_fta.status = 'PENDING_VRM_CHANGE' or liberator_permit_fta.status = 'Created' or liberator_permit_fta.status = 'PENDING_ADDR_CHANGE' or liberator_permit_fta.status = 'PAYMENT_RECEIVED'),1
,if(
	(liberator_permit_renewals.renewal_payment_status = 'Renewed' or liberator_permit_renewals.renewal_payment_status = 'Approved' or liberator_permit_renewals.renewal_payment_status = 'ORDER_APPROVED' or liberator_permit_renewals.renewal_payment_status = 'PENDING_VRM_CHANGE' or liberator_permit_renewals.renewal_payment_status = 'Created' or liberator_permit_renewals.renewal_payment_status = 'PENDING_ADDR_CHANGE' or liberator_permit_renewals.renewal_payment_status = 'PAYMENT_RECEIVED')
 , 1, 0)) 

,liberator_permit_fta.permit_type --as voucher_period
 ,substr(liberator_permit_fta.permit_reference,1,3)
 ,case
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYA' then 'All zone'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYG' then 'Companion Badge'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYB' then 'Business'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYD' then 'Doctor'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYP' then 'Estate resident'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYH' then 'Health and social care'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYR' then 'Residents'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYL' then 'Leisure Centre Permit'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYE' then 'All Zone Business Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYF' then 'Film Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYJ' then 'Health and Social Care Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYQ' then 'Estate Visitor Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) = 'HYV' then 'Resident Visitor Voucher'
 when substr(liberator_permit_fta.permit_reference,1,3) ='HYN' then 'Dispensation'
 when liberator_permit_fta.permit_reference ='HY50300' then 'Dispensation'
 else substr(liberator_permit_fta.permit_reference,1,3)
 end

,Case when substr(liberator_permit_fta.permit_reference,1,3) ='HYE' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYF' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYQ' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYV' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYJ' then 'Voucher'
when substr(liberator_permit_fta.permit_reference,1,3)='HYN' then 'Dispensation'
when liberator_permit_fta.permit_reference ='HY50300' then 'Dispensation'
when substr(liberator_permit_fta.permit_reference,1,3)='HYS' then 'Suspension' else 'Permit'
end

,case when (substr(liberator_permit_fta.permit_reference,1,3) ='HYE' or 
 substr(liberator_permit_fta.permit_reference,1,3)='HYF'or
substr(liberator_permit_fta.permit_reference,1,3)='HYQ' or
substr(liberator_permit_fta.permit_reference,1,3)='HYV' or
substr(liberator_permit_fta.permit_reference,1,3)='HYJ' ) and
 liberator_permit_fta.e_voucher ='E' then 'eVoucher'
when (substr(liberator_permit_fta.permit_reference,1,3) ='HYE' or 
 substr(liberator_permit_fta.permit_reference,1,3)='HYF'or
substr(liberator_permit_fta.permit_reference,1,3)='HYQ' or
substr(liberator_permit_fta.permit_reference,1,3)='HYV' or
substr(liberator_permit_fta.permit_reference,1,3)='HYJ' ) and
 liberator_permit_fta.e_voucher <> 'E' then 'Paper Voucher' else 'Not Voucher' end
,   liberator_permit_fta.import_year
,	liberator_permit_fta.import_month
,	liberator_permit_fta.import_day
,	liberator_permit_fta.import_date

order by 
-- to_date(Substr(liberator_permit_fta.application_date, 1,7), '%Y-%m') desc 
cast(concat(substr(Cast(liberator_permit_fta.application_date as varchar(10)),1, 7), '-01') as date)
, liberator_permit_fta.cpz, liberator_permit_fta.cpz_name
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_permit_fta": S3bucketRawliberator_permit_fta_node1,
        "liberator_permit_renewals": AmazonS3rawliberator_permit_renewals_node1643219669907,
        "dc_liberator_latest_permit_status": AmazonS3refineddc_liberator_latest_permit_status_node1643219673143,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket - parking_vouchers_approved_summary_gds
S3bucketparking_vouchers_approved_summary_gds_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_vouchers_approved_summary_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucketparking_vouchers_approved_summary_gds_node3",
)
S3bucketparking_vouchers_approved_summary_gds_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_vouchers_approved_summary_gds",
)
S3bucketparking_vouchers_approved_summary_gds_node3.setFormat("glueparquet")
S3bucketparking_vouchers_approved_summary_gds_node3.writeFrame(ApplyMapping_node2)
job.commit()
