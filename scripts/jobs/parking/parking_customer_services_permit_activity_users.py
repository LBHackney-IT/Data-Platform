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

# Script generated for node Amazon S3 - liberator_permit_activity
AmazonS3liberator_permit_activity_node1715091109305 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-raw-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="liberator_permit_activity", transformation_ctx="AmazonS3liberator_permit_activity_node1715091109305")

# Script generated for node SQL Query - parking_customer_services_permit_activity_users
SqlQuery0 = '''
/*Parking Customer Services - Permit Activity summarised for specific users by 
- Actvity Financial year
- Actvity Month year 
- Actvity Date 
- Actvity Hour
- Product Type 
- Product Category

07/05/2024 - CREATED

*/

With act_data as (
Select 
Case
when cast(activity_date as varchar(10)) like '2031-03-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2031-02-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2031-01-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-12-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-11-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-10-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-09-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-08-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-07-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-06-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-05-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-04-%'  THEN '2027' --2030 to 2031

when cast(activity_date as varchar(10)) like '2030-03-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-02-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2030-01-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-12-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-11-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-10-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-09-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-08-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-07-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-06-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-05-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-04-%'  THEN '2027' --2029 to 2030

when cast(activity_date as varchar(10)) like '2029-03-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-02-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2029-01-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-12-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-11-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-10-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-09-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-08-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-07-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-06-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-05-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-04-%'  THEN '2027' --2028 to 2029

when cast(activity_date as varchar(10)) like '2028-03-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-02-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2028-01-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-12-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-11-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-10-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-09-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-08-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-07-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-06-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-05-%'  THEN '2027'
when cast(activity_date as varchar(10)) like '2027-04-%'  THEN '2027' --2027 to 2028
when cast(activity_date as varchar(10)) like '2027-03-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2027-02-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2027-01-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-12-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-11-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-10-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-09-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-08-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-07-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-06-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-05-%'  THEN '2026'
when cast(activity_date as varchar(10)) like '2026-04-%'  THEN '2026' --2026 to 2027
when cast(activity_date as varchar(10)) like '2026-03-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2026-02-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2026-01-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-12-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-11-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-10-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-09-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-08-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-07-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-06-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-05-%'  THEN '2025'
when cast(activity_date as varchar(10)) like '2025-04-%'  THEN '2025' --2025 to 2026
when cast(activity_date as varchar(10)) like '2025-03-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2025-02-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2025-01-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-12-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-11-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-10-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-09-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-08-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-07-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-06-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-05-%'  THEN '2024'
when cast(activity_date as varchar(10)) like '2024-04-%'  THEN '2024' --2024 to 2025
when cast(activity_date as varchar(10)) like '2024-03-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2024-02-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2024-01-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-12-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-11-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-10-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-09-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-08-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-07-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-06-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-05-%'  THEN '2023'
when cast(activity_date as varchar(10)) like '2023-04-%'  THEN '2023' --2023 to 2024
when cast(activity_date as varchar(10)) like '2023-03-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2023-02-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2023-01-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-12-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-11-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-10-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-09-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-08-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-07-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-06-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-05-%'  THEN '2022'
when cast(activity_date as varchar(10)) like '2022-04-%'  THEN '2022' --2022 to 2023
when cast(activity_date as varchar(10)) like '2022-03-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2022-02-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2022-01-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-12-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-11-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-10-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-09-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-08-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-07-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-06-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-05-%'  THEN '2021'
when cast(activity_date as varchar(10)) like '2021-04-%'  THEN '2021' --2021 to 2022
when cast(activity_date as varchar(10)) like '2021-03-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2021-02-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2021-01-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-12-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-11-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-10-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-09-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-08-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-07-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-06-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-05-%'  THEN '2020'
when cast(activity_date as varchar(10)) like '2020-04-%'  THEN '2020' --2020 to 2021
when cast(activity_date as varchar(10)) like '2020-03-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2020-02-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2020-01-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-12-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-11-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-10-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-09-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-08-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-07-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-06-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-05-%'  THEN '2019'
when cast(activity_date as varchar(10)) like '2019-04-%'  THEN '2019' --2019 to 2020
when cast(activity_date as varchar(10)) like '2019-03-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2019-02-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2019-01-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-12-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-11-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-10-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-09-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-08-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-07-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-06-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-05-%'  THEN '2018'
when cast(activity_date as varchar(10)) like '2018-04-%'  THEN '2018' --2018 to 2019
when cast(activity_date as varchar(10)) like '2018-03-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2018-02-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2018-01-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-12-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-11-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-10-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-09-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-08-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-07-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-06-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-05-%'  THEN '2017'
when cast(activity_date as varchar(10)) like '2017-04-%'  THEN '2017' --2017 to 2018
when cast(activity_date as varchar(10)) like '2017-03-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2017-02-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2017-01-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-12-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-11-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-10-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-09-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-08-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-07-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-06-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-05-%'  THEN '2016'
when cast(activity_date as varchar(10)) like '2016-04-%'  THEN '2016' --2016 to 2017
when cast(activity_date as varchar(10)) like '2016-03-%'  THEN '2015'
when cast(activity_date as varchar(10)) like '2016-02-%'  THEN '2015' --2015 to 2016
when cast(activity_date as varchar(10)) like '1970-01-01' THEN '1969' 
when cast(activity_date as varchar(10)) like '1970-01-26' THEN '1969' --1969
else '1900'
end as fy
,concat(substr(Cast(activity_date as varchar(10)),1, 7), '-01') as act_MonthYear
,substr(cast(activity_date as varchar(40)), 1, 10) as act_date ,substr(cast(activity_date as varchar(40)), 12, 2) as act_hour 
,case 
when substr(permit_referece,1,3) = 'HYA' then 'All zone'
when substr(permit_referece,1,3) = 'HYG' then 'Companion Badge'
when substr(permit_referece,1,3) = 'HYB' then 'Business'
when substr(permit_referece,1,3) = 'HYD' then 'Doctor'
when substr(permit_referece,1,3) = 'HYP' then 'Estate resident'
when substr(permit_referece,1,3) = 'HYH' then 'Health and social care'
when substr(permit_referece,1,3) = 'HYR' then 'Residents'
when substr(permit_referece,1,3) = 'HYL' then 'Leisure Centre Permit'
when substr(permit_referece,1,3) = 'HYE' then 'All Zone Business Voucher'
when substr(permit_referece,1,3) = 'HYF' then 'Film Voucher'
when substr(permit_referece,1,3) = 'HYJ' then 'Health and Social Care Voucher'
when substr(permit_referece,1,3) = 'HYQ' then 'Estate Visitor Voucher'
when substr(permit_referece,1,3) = 'HYV' then 'Resident Visitor Voucher'
when substr(permit_referece,1,3) = 'HYN' then 'Dispensation'
when permit_referece ='HY50300' then 'Dispensation'
when substr(permit_referece,1,3) = 'HYS' then 'Suspension'
else substr(permit_referece,1,3)
end as product_type
,case
when substr(permit_referece,1,3) = 'HYE' then 'Voucher'
when substr(permit_referece,1,3) = 'HYF' then 'Voucher'
when substr(permit_referece,1,3) = 'HYQ' then 'Voucher'
when substr(permit_referece,1,3) = 'HYV' then 'Voucher'
when substr(permit_referece,1,3) = 'HYJ' then 'Voucher'
when substr(permit_referece,1,3) = 'HYN' then 'Dispensation'
when permit_referece ='HY50300' then 'Dispensation'
when substr(permit_referece,1,3) = 'HYS' then 'Suspension' else 'Permit'
end as product_category

/*Activity tag group*/
,case
when upper(activity) like 'ACTIVATE VOUCHER MAIL SENT FOR CONFIRMATION.' then 'ACTIVATION'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: A JOB DESCRIPTION FROM CUSTOMER%' then 'JOB DESCRIPTION'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER%' then 'BLUE BADGE - FRONT AND BACK'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE BACK FROM CUSTOMER%' then 'BLUE BADGE - BACK'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE FRONT FROM CUSTOMER%' then 'BLUE BADGE - FRONT'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: CORPORATE TAX OR VAT RETURN FROM CUSTOMER%' then 'TAX OR VAT'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: DOCUMENTATION REQUESTED BY EMAIL FROM CUSTOMER%' then 'DOCUMENTATION'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: DRIVING LICENCE FROM CUSTOMER%' then 'DRIVING LICENCE'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: LETTER FROM RELEVANT RELIGIOUS LEADER FROM CUSTOMER%' then 'RELIGIOUS LEADER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: LETTER FROM YOUR ORGANISATION, SIGNED BY YOUR LINE MANAGER IN SUPPORT OF PERMIT APPLICANT%' then 'LINE MANAGER IN SUPPORT'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: LGP CONVERSION CERTIFICATE FROM CUSTOMER%' then 'LGP CONVERSION CERTIFICATE'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: REMOVAL COMPANY DETAILS FROM CUSTOMER%' then 'REMOVAL COMPANY DETAILS'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: VEHICLE LOG BOOK FROM CUSTOMER%' then 'VEHICLE LOG BOOK'
when upper(activity) like 'APPLICATION SENT TO ASSISTANT DIRECTOR%' then 'APPLICATION SENT TO ASSISTANT DIRECTOR'
when upper(activity) like 'BOOK VOUCHER MAIL SENT FOR CONFIRMATION.' then 'BOOK VOUCHER' --Book voucher mail sent for confirmation.
when upper(activity) like 'CANCEL VOUCHER MAIL SENT FOR CONFIRMATION.' then 'CANCEL VOUCHER'
when upper(activity) like 'CHANGE ADDRESS REQUEST HAS BEEN REJECTED.' then 'REJECT ADDRESS CHANGE'
when upper(activity) like 'CHANGED PERMIT VRM%' then 'VRM CHANGE'
when upper(activity) like 'CITYPAY REFUND PROCESSED, REFUND' then 'CITYPAY REFUND'
when upper(activity) like 'CITYPAY REFUND PROCESSED, REFUND % FAILED%' then 'CITYPAY REFUND - FAILED'
when upper(activity) like 'CITYPAY REFUND PROCESSED, REFUND % PROCESSED%' then 'CITYPAY REFUND - PROCESSED'
when upper(activity) like 'CONFIRMATION OF VOUCHER BOOKING.' then 'BOOK VOUCHER'
when upper(activity) like 'CONTACT CENTRE ACTION CREATED%' then 'CREATED'
when upper(activity) like 'CONTACT CENTRE ACTION REQUEST FOR PERMIT REFERENCE%' then 'REQUEST FOR PERMIT REFERENCE'
when upper(activity) like 'DELETE VOUCHER MAIL SENT FOR CONFIRMATION%' then 'DELETE VOUCHER'
when upper(activity) like 'DISCOUNTED VOUCHER BOOKS REFUNED%' then 'DISCOUNTED VOUCHER REFUND'
when upper(activity) like 'DISPENSATION REMOVED' then 'REMOVED DISPENSATION'
when upper(activity) like 'DISPENSATION VRM REQUIRED REMINDER SENT' then 'VRM REQUIRED'
when upper(activity) like 'E VOUCHER MAIL SENT FOR ACTIVATION.' then 'ACTIVATION'
when upper(activity) like 'EMAI OF REJECTION SENT%' then 'REJECTION SENT'
when upper(activity) like 'EMAIL OF APPROVAL SENT%' then 'APPROVAL SENT'
when upper(activity) like 'EMAIL OF CANCELLATION SENT%' then 'CANCELLATION SENT'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOU HAVE PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL' then 'PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOU HAVE UNPAID INVOICES FOR PREVIOUS SUSPENSION(S)' then 'UNPAID INVOICES FOR PREVIOUS SUSPENSION(S)'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION' then 'APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION APPLICATION IS NOT A GENUINE EMERGENCY' then 'APPLICATION IS NOT A GENUINE EMERGENCY'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS (SEE BELOW FOR DETAILS)' then 'APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION WOULD CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA' then 'CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION WOULD CREATE UNACCEPTABLE PARKING STRESS IN THE AREA' then 'CREATE UNACCEPTABLE PARKING STRESS IN THE AREA'
when upper(activity) like 'EMAIL OF REJECTION SENT%' then 'REJECTION SENT'
when upper(activity) like 'EMAIL SENT TO FILMING OFFICE%' then 'EMAIL SENT TO FILMING OFFICE' --email sent to Filming office11/04/2017
when upper(activity) like 'EVIDENCE REMINDER SENT' then 'EVIDENCE REMINDER'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 A LETTER FROM YOUR ORGANISATION, SIGNED BY YOUR LINE MANAGER IN SUPPORT OF PERMIT APPLICANT% APPLICATION FROM CUSTOMER FOR%' then 'LINE MANAGER IN SUPPORT' --Evidence requested again: 1 A Letter from your organisation, signed by your line manager in support of permit applicantâ€™s application from Customer for HYH12690247
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (BACK OF BLUE BADGE) FROM CUSTOMER FOR %' then 'BLUE BADGE - BACK' --Evidence requested again: 1 Blue badge (back of blue badge) from Customer for HYG9063640
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER FOR%' then 'BLUE BADGE - FRONT AND BACK' --Evidence requested again: 1 Blue badge (front and back of blue badge) from Customer for HYG0999184
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (FRONT OF BLUE BADGE) FROM CUSTOMER FOR %' then 'BLUE BADGE - FRONT' --Evidence requested again: 1 Blue badge (front of blue badge) from Customer for HYG9303744
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 LPG CONVERSION CERTIFICATE FROM CUSTOMER FOR%' then 'LGP CONVERSION CERTIFICATE' --Evidence requested again: 1 LPG Conversion Certificate from Customer for HYR1380158
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PERMIT APPLICANT% JOB DESCRIPTION FROM CUSTOMER FOR%' then 'JOB DESCRIPTION' --Evidence requested again: 1 Permit applicantâ€™s job description from Customer for HYH12690247
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF BUSINESS AT THIS ADDRESS FROM CUSTOMER FOR %' then 'PROOF BUSINESS AT THIS ADDRESS' --Evidence requested again: 1 proof business at this address from Customer for HYB7312888
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF ADDRESS FROM CUSTOMER FOR%' then 'PROOF OF BUSINESS WORKS' --Evidence requested again: null proof of address from Customer for HYR4946492
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF BUSINESS WORKS FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF BUSINESS WORKS FROM CUSTOMER' --Evidence requested again: 1 proof of business works from Customer for HYN11136834
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF VEHICLE INFORMATION FROM CUSTOMER%' then 'PROOF OF VEHICLE INFORMATION' --Evidence requested again: 1 proof of vehicle information from Customer for HYR9942251
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF WEDDING  FROM CUSTOMER%' then 'PROOF OF WEDDING '
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (BACK OF BLUE BADGE) FROM CUSTOMER%' then 'BLUE BADGE - BACK'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER%' then 'BLUE BADGE - FRONT AND BACK'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (FRONT OF BLUE BADGE) FROM CUSTOMER FOR %' then 'BLUE BADGE - FRONT' --Evidence requested again: 1 Blue badge (back of blue badge) from Customer for HYG7461744
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL DOCUMENTATION REQUESTED BY EMAIL FROM CUSTOMER FOR %' then 'DOCUMENTATION' --Evidence requested again: null Documentation requested by email from Customer for HYS11582596
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL LPG CONVERSION CERTIFICATE FROM CUSTOMER FOR%' then 'LGP CONVERSION CERTIFICATE' --Evidence requested again: null LPG Conversion Certificate from Customer for HYP4205978
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL PROOF BUSINESS AT THIS ADDRESS FROM CUSTOMER%' then 'PROOF BUSINESS AT THIS ADDRESS'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL PROOF OF ADDRESS FROM CUSTOMER FOR%' then 'PROOF OF ADDRESS' --Evidence requested again: null proof of address from Customer for HYG4978685
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL PROOF OF VEHICLE INFORMATION FROM CUSTOMER FOR%' then 'PROOF OF VEHICLE INFORMATION' --Evidence requested again: null proof of vehicle information from Customer for HYB5776458
when upper(activity) like 'EXTEND VOUCHER MAIL SENT FOR CONFIRMATION.' then 'EXTEND VOUCHER' --Extend voucher mail sent for confirmation.
when upper(activity) like 'EXTENSION REQUEST IS APPROVED BY : ' then 'APPROVAL' --Extension request is approved by : Extension request is approved by :
when upper(activity) like 'EXTENSION REQUEST IS REJECTED: ' then 'REJECTION'  --Extension request is rejected: 
when upper(activity) like 'FULL PRICE VOUCHER BOOKS REFUNED' then 'FULL PRICE VOUCHER REFUND'
when upper(activity) like 'FULL PRICE VOUCHER BOOKS REFUNED %. REFUND AMOUNT%' then 'FULL PRICE VOUCHER REFUND' --Full price voucher books refuned 1. Refund amount: £20.50
when upper(activity) like 'MANUAL REFUND PROCESSED, REFUND OF % HAS BEEN PROCESSED ON %' then 'MANUAL REFUND PROCESSED' --Manual refund processed, Refund of £7.75 has been processed on 17/11/2022 00:00
when upper(activity) like 'ON LBH INSTRUCTION PERMIT STATUS CHANGED TO ORDER RENEW' then 'LBH INSTRUCT PERMIT STATUS CHANGE'
when upper(activity) like 'ORDER QUANTITY SET TO%' then 'ORDER QUANTITY SET'
when upper(activity) like 'PERMIT ADDRESS WILL BE CHANGED%' then 'PERMIT ADDRESS WILL BE CHANGED'
when upper(activity) like 'PERMIT HAS BEEN PRINTED LOCALLY%' then 'PERMIT HAS BEEN PRINTED LOCALLY'
when upper(activity) like 'PERMIT HAS BEEN SENT FOR PRINTING%' then 'PERMIT HAS BEEN SENT FOR PRINTING'
when upper(activity) like 'PERMIT HAS BEEN SENT FOR VIRTUAL COVER%' then 'PERMIT HAS BEEN SENT FOR VIRTUAL COVER'
when upper(activity) like 'PERMIT RENEWAL REJECTED PAYMENT FAILURE%' then 'REJECTED PAYMENT FAILURE'
when upper(activity) like 'PERMIT RENEWAL REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED%' then 'REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED' 
when upper(activity) like 'PERMIT RENEWAL REJECTED WITH REFUND%' then 'REJECTED WITH REFUND'
when upper(activity) like 'PERMIT RENEWAL REJECTED YOUR APPLICATION NOT MEETING THIS PERMIT%S CRITERIA%' then 'REJECTED YOUR APPLICATION NOT MEETING THIS PERMITS CRITERIA'
when upper(activity) like 'PERMIT RENEWAL ACCEPTED%' then 'ACCEPTED'
when upper(activity) like 'PERMIT RENEWAL REJECTED%' then 'REJECTED'
when upper(activity) like 'PERMIT RENEWED%' then 'RENEWED'
when upper(activity) like 'PERMIT STATUS CHANGED' then 'CHANGED PERMIT STATUS' 
when upper(activity) like 'PERMIT STATUS CHANGED TO  ' then 'CHANGED PERMIT STATUS' --Permit status changed to  
when upper(activity) like 'PERMIT STATUS CHANGED TO  APPROVED' then 'APPROVED PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO  CANCELLED' then 'CANCELLED PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO  LOST' then 'LOST PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO  PERMIT STATUS CHANGED TO LOST %WITH ADMIN FEE PAYMENT OF %' then 'LOST PERMIT STATUS' -- Permit status changed to  Permit status changed to lost  with admin fee payment of Â£10 received 
when upper(activity) like 'PERMIT STATUS CHANGED TO  PERMIT STATUS CHANGED TO DAMAGED  WITH ADMIN FEE PAYMENT' then 'DAMAGED PERMIT STATUS' 
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED.' OR  upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED' then 'REJECTED PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF VEHICLE REGISTRATIONS NOT PROVIDED' then 'REJECTED PERMIT STATUS - VEHICLE REGISTRATIONS NOT PROVIDED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF REQUESTED EVIDENCE NOT BEING PROVIDED' then 'REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED'  --Permit status changed to  rejected because of requested evidence not being provided
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR APPLICATION NOT MEETING THIS PERMIT%S CRITERIA' then 'REJECTED YOUR APPLICATION NOT MEETING THIS PERMITS CRITERIA'  --Permit status changed to  rejected because of your application not meeting this permit's criteria
when upper(activity) like 'PERMIT STATUS CHANGED TO  RENEWAL - EVIDENCE SUBMITTED%' then 'RENEWAL PERMIT STATUS - EVIDENCE SUBMITTED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  STOLEN%' then 'STOLEN PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO  VRM CHANGE%' then 'VRM CHANGE PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO CANCELLED% ' then 'CANCELLED PERMIT STATUS '
when upper(activity) like 'PERMIT STATUS CHANGED TO LOST%' then 'LOST PERMIT STATUS'
when upper(activity) like 'PERMIT STATUS CHANGED TO REJECTED AS REQUESTED%' then 'REJECTED PERMIT STATUS - REQUESTED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF PAYMENT FAILURE' then 'REJECTED PERMIT STATUS - PAYMENT FAILURE'  --Permit status changed to  rejected because of payment failure
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR VEHICLE NOT REQUIRING A PERMIT' then 'REJECTED PERMIT STATUS - VEHICLE NOT REQUIRING A PERMIT'   --Permit status changed to  rejected because of your vehicle not requiring a permit
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF THE FILM OFFICE DECLINING THE VOUCHER APPLICATION' then 'REJECTED PERMIT STATUS - FILM OFFICE DECLINING THE VOUCHER APPLICATION' --Permit status changed to  rejected because of the film office declining the voucher application
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOU HAVING 3 OR MORE OUTSTANDING PCNS THAT REQUIRE PAYMENT' then 'REJECTED PERMIT STATUS - OUTSTANDING PCNS' --Permit status changed to  rejected because of you having 3 or more outstanding PCNs that require payment
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOU NOT LIVING IN THE BOROUGH' then 'REJECTED PERMIT STATUS - NOT LIVING IN THE BOROUGH'  --Permit status changed to  rejected because of you not living in the borough
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING IN A PARKING ZONE' then 'REJECTED PERMIT STATUS - ADDRESS NOT BEING IN A PARKING ZONE'  --Permit status changed to  rejected because of your address not being in a parking zone
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING LOCATED WITHIN A CONTROLLED PARKING ZONE IN HACKNEY' then 'REJECTED PERMIT STATUS - ADDRESS NOT BEING LOCATED WITHIN A CONTROLLED PARKING ZONE IN HACKNEY'  --Permit status changed to  rejected because of your address not being located within a controlled parking zone in Hackney
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING LOCATED WITHIN THE LONDON BOROUGH OF HACKNEY' then 'REJECTED PERMIT STATUS - ADDRESS NOT BEING LOCATED WITHIN THE LONDON BOROUGH OF HACKNEY' --Permit status changed to  rejected because of your address not being located within the London borough of Hackney
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR PERMIT ADDRESS BEING IN A CAR FREE DEVELOPMENT' then 'REJECTED PERMIT STATUS - ADDRESS BEING IN A CAR FREE DEVELOPMENT'--Permit status changed to  rejected because of your permit address being in a car free development
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS' then 'REJECTED PERMIT STATUS - VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS'--Permit status changed to  rejected because of your vehicle exceeding the maximum dimensions
when upper(activity) like 'PERMIT THEFT REPORT HAS BEEN ACCEPTED FOR REFERENCE%' then 'PERMIT THEFT REPORT'
when upper(activity) like 'PERMIT%S CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN ACCEPTED%' then 'ACCEPTED VEHICLE CHANGE'
when upper(activity) like 'PERMIT%S CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN ACCEPTED FOR%' then 'ACCEPTED VEHICLE CHANGE'
when upper(activity) like 'PERMIT%S CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN REJECTED%' then 'REJECTED VEHICLE CHANGE'
when upper(activity) like 'PERSONAL BAY ADDED REFERENCE NUMBER % INSTALLATION DATE%' then 'PERSONAL BAY - ADDED' --Personal Bay added Reference Number 00156 Installation Date 9/8/2021
when upper(activity) like 'PERSONAL BAY REMOVED REFERENCE NUMBER % REMOVAL DATE%' then 'PERSONAL BAY - REMOVED' --Personal Bay removed Reference Number 00013 Removal Date 2/8/2022
when upper(activity) like 'REASON FOR THE REJECTION: YOU HAVE PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL. REFUND AMOUNT%' then 'PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL' --Reason for the rejection: you have previously failed to adhere to the terms and conditions of suspension requests granted by Hackney Council. Refund amount: Â£184.50
when upper(activity) like 'REASON FOR THE REJECTION: YOU HAVE UNPAID INVOICES FOR PREVIOUS SUSPENSION(S). REFUND AMOUNT%' then 'UNPAID INVOICES FOR PREVIOUS SUSPENSION(S)'
when upper(activity) like 'REASON FOR THE REJECTION: YOUR APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION. REFUND AMOUNT%' then 'APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION' --Reason for the rejection: your application contains insufficient or contradictory information. Refund amount: £213.00
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION APPLICATION IS NOT A GENUINE EMERGENCY. REFUND AMOUNT%' then 'APPLICATION IS NOT A GENUINE EMERGENCY'
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS (SEE BELOW FOR DETAILS). REFUND AMOUNT%' then 'APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS' --Reason for the rejection: your suspension application needs to be re-applied for with updated details (see below for details). Refund amount: £212.50
--Reason for the rejection: your suspension application needs to be re-applied for with updated details (see below for details). Refund amount: £395.50
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION WOULD CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA. REFUND AMOUNT%' then 'CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA'
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION WOULD CREATE UNACCEPTABLE PARKING STRESS IN THE AREA. REFUND AMOUNT%' then 'CREATE UNACCEPTABLE PARKING STRESS IN THE AREA'
when upper(activity) like 'REFUND DUE TO CUSTOMER' then 'REFUND DUE TO CUSTOMER'
when upper(activity) like 'REFUND DUE TO CUSTOMER PERMIT WAS AUTO-APPROVED INCORRECTLY. A FULL REFUND DONE BY MINDMILL MANUALLY.' then 'REFUND DUE TO CUSTOMER - MANUALLY - AUTO-APPROVED INCORRECTLY'
when upper(activity) like 'REFUND WAS SUPRESSED' then 'REFUND SUPRESSED' 
when upper(activity) like 'REFUND OF % WAS SUPRESSED BY %' then 'REFUND SUPRESSED' --Refund of £84.92 was supressed by dmoses
when upper(activity) like 'REFUND OF % DUE TO CUSTOMER' then 'REFUND DUE TO CUSTOMER' --Refund of £20.00 due to customer
when upper(activity) like 'RENEWAL REMINDER SENT TO CUSTOMER FOR PERMIT REFERENCE%' then 'REMINDER SENT - CUSTOMER'
when upper(activity) like 'RENEWAL REMINDER IS NOT SENT FOR PERMIT REFERENCE%' then 'REMINDER IS NOT SENT'
when upper(activity) like 'RENEWAL REMINDER SENT TO CUSTOMER%' then 'REMINDER SENT - CUSTOMER'
when upper(activity) like 'RENEWAL REMINDER SENT' then 'REMINDER SENT'
when upper(activity) like 'ROLE ADDED, USER HAS AN APPROVED HASC ACCOUNT' then 'ACCOUNT ROLE ADDED - HASC'
when upper(activity) like 'SUCCESSFUL APPLICATION WITH PAYMENT%' then 'SUCCESSFUL APPLICATION -  PAYMENT'
when upper(activity) like 'SUSPENSION' then 'SUSPENSION'
when upper(activity) like '%SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION REFUND IN COST% START AND END DATES ARE%' then 'AMEND SUSPENSION REFUND IN COST'  -- Suspension amended and approved. Amend suspension refund in cost: £408. Start and end dates are: 2021-05-17 00:00:00.0 and 2021-05-20 00:00:00.0 -- Suspension amended and approved. Amend suspension refund in cost: £170. Start and end dates are: 2021-12-06 00:00:00.0 and 2021-12-10 00:00:00.0
when upper(activity) like '%SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION WITH INCREASE IN COST AND PAYMENT RECEIVED% START AND END DATES ARE%' then 'AMEND SUSPENSION WITH INCREASE IN COST AND PAYMENT RECEIVED' -- Suspension amended and approved. Amend suspension with increase in cost and payment received: £68. Start and end dates are: 2021-10-12 00:00:00.0 and 2021-10-13 00:00:00.0  -- Suspension amended and approved. Amend suspension with increase in cost and payment received: £136. Start and end dates are: 2021-04-15 00:00:00.0 and 2021-04-18 00:00:00.0
when upper(activity) like '%SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION WITH NO CHANGE IN COST. START AND END DATES ARE%' then 'AMEND SUSPENSION WITH NO CHANGE IN COST'  --Suspension amended and approved. Amend suspension with no change in cost. Start and end dates are: 2023-09-11 00:00:00.0 and 2023-09-11 00:00:00.0
when upper(activity) like 'SUSPENSION DUE TO BE CANCELLED ON %. REFUND AMOUNT%' then 'CANCELLED SUSPENSION' -- Suspension due to be cancelled on 2022-04-13 00:00:00.0. Refund amount: £114.50
when upper(activity) like 'SUSPENSION DURATION CHANGED. CHANGE DURATION WITH INCREASE IN COST%' then 'CHANGE DURATION WITH INCREASE IN COST'
when upper(activity) like '%SUSPENSION DURATION CHANGED. CHANGE DURATION WITH REFUND IN COST:%OLD SUSPENSION START AND END DATES ARE%' then 'CHANGE DURATION WITH REFUND IN COST' -- Suspension duration changed. Change duration with refund in cost: Â£102.000. Old suspension start and end dates are : 2020-11-14 00:00:00.0 and 2020-11-15 00:00:00.0 -- Suspension duration changed. Change duration with refund in cost: Â£102.000. Old suspension start and end dates are : 2020-11-14 00:00:00.0 and 2020-11-15 00:00:00.0
when upper(activity) like '%SUSPENSION DURATION CHANGED. OLD SUSPENSION START AND END DATES ARE%' then 'OLD SUSPENSION START AND END DATES' -- Suspension duration changed. Old suspension start and end dates are : 2017-04-03 00:00:00.0 and 2017-04-07 00:00:00.0 -- Suspension duration changed. Old suspension start and end dates are : 2017-04-03 00:00:00.0 and 2017-04-07 00:00:00.0
when upper(activity) like 'SUSPENSION EXTENSION APPROVED' then 'SUSPENSION - EXTENSION APPROVED' --Suspension extension approved
when upper(activity) like 'SUSPENSION UPDATE TO SIGN UP' then 'SUSPENSION - SIGN UP'
when upper(activity) like 'SUSPENSION UPDATE TO SUSPENSION REJECT' then 'SUSPENSION - REJECT'
when upper(activity) like '%SUSPENSION UPDATE TO SUSPENSION APPROVED%' then 'SUSPENSION - UPDATE TO APPROVED' --Suspension update to Suspension Approved
when upper(activity) like 'TEMPORARY PERMIT PRINTED STARTING % ENDING %' then 'PRINTED TEMPORARY PERMIT' --Temporary permit printed starting 04/05/2017 ending 04/06/2017
when upper(activity) like 'THE CRIME REFERENCE NUMBER HAS NOT BEEN CONFIRMED BY THE POLICE AND SO A FREE REPLACEMENT IS NOT POSSIBLE FOR REFERENCE%' then 'CRIME REFERENCE NUMBER HAS NOT BEEN CONFIRMED BY THE POLICE AND SO A FREE REPLACEMENT IS NOT POSSIBLE'
when upper(activity) like 'THE PROTECTED VEHICLE WAS CHANGED%' then 'PROTECTED VEHICLE WAS CHANGED'
when upper(activity) like 'THE SUSPENSION MANUALLY SIGN HAS BEEN UPDATED. THE IDENTIFIER IS%' then 'SUSPENSION MANUALLY SIGN'
when upper(activity) like 'UPDATE VOUCHER MAIL SENT FOR CONFIRMATION.' then 'UPDATE VOUCHER'
when upper(activity) like 'VEHICLE REGISTRATION NUMBER:%' then 'VEHICLE REGISTRATION NUMBER'
when upper(activity) like 'VEHICLE UPDATED ON PERMIT . OLD VEHILCE DETAILS ARE : VRM%' OR upper(activity) like ' VEHICLE UPDATED ON PERMIT . OLD VEHILCE DETAILS ARE : VRM :%' then 'VEHICLE UPDATED' -- Vehicle updated on permit . Old vehilce details are : vrm : AO05COH Emission (CO2) : 180 manufacturer : VOLKSWAGEN model : POLO TWIST AUTO. Permit charge were 112.000 --Vehicle updated on permit . Old vehilce details are : vrm : DG11VUM Emission (CO2) : 132 manufacturer : HONDA model : CIVIC TYPE-S I-VTEC S-A. Permit charge were 43.000
when upper(activity) like 'VEHICLES ON DISPENSATION CHANGED FROM NULL%' then 'VEHICLES ON DISPENSATION CHANGED'
when upper(activity) like 'VEHICLES ON DISPENSATION CHANGED%' then 'VEHICLES ON DISPENSATION CHANGED'
when upper(activity) like 'VOUCHER HAS BEEN MARKED AS SENT TO PRINT%' then 'MARKED AS SENT TO PRINT'
when upper(activity) like 'VOUCHER COVER LETTER HAS BEEN PRINTED' then 'COVER LETTER HAS BEEN PRINTED'
when upper(activity) like 'VOUCHER SENT TO LIBERTY' then 'SENT TO LIBERTY'
when upper(activity) like 'VOUCHER SERIAL NUMBERS UPDATED%' then 'SERIAL NUMBERS UPDATED'
when upper(activity) like 'VOUCHER SESSIONS OVERRIDDEN%' then 'VOUCHER SESSIONS OVERRIDDEN'
when upper(activity) like 'VOUCHER SHIPPED LOCALLY' then 'SHIPPED LOCALLY'
when upper(activity) like 'VRM % WILL BE REMOVED WITH EFFECT FROM%' then 'VRM WILL BE REMOVED - EFFECT FROM' --VRM GJ52XEM will be removed with effect from 04/05/2017
when upper(activity) like 'VRM % WILL BE REMOVED WITH REFUND' or upper(activity) like 'VRM % WILL BE REMOVED WITH REFUND OF % WITH EFFECT FROM%' then 'VRM WILL BE REMOVED - REFUND' --VRM T321NMH WILL BE REMOVED WITH REFUND OF Â£-181.26 WITH EFFECT FROM 09/02/2024
when upper(activity) like '%VRM CHANGE ACCEPTED%' then 'VRM CHANGE - ACCEPTED' --VRM CHANGE ACCEPTED
when upper(activity) like 'VRM CHANGE APPLICATION' then 'VRM CHANGE  - APPLICATION'
when upper(activity) like 'VRM CHANGE APPLICATION % SENT ON%' OR upper(activity) like 'VRM CHANGE APPLICATION SENT ON%' then 'VRM CHANGE  - APPLICATION SENT' --Vrm change application Â£null sent on 31/05/2017 --Vrm change application sent on 01/03/2017
when upper(activity) like 'VRM CHANGE APPLICATION WITH PAYMENT OF % SENT ON %' then 'VRM CHANGE  - APPLICATION WITH PAYMENT' --Vrm change application with payment of £8.96 sent on 19/12/2023
when upper(activity) like 'VRM CHANGE REJECTED PAYMENT FAILURE' then 'VRM CHANGE - REJECTED PAYMENT FAILURE'
when upper(activity) like 'VRM CHANGE REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED' then 'VRM CHANGE - REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED'
when upper(activity) like 'VRM CHANGE REJECTED YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS' then 'VRM CHANGE - REJECTED YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS'
when upper(activity) like 'VRM CHANGE REJECTED YOUR VEHICLE NOT REQUIRING A PERMIT' then 'VRM CHANGE - REJECTED YOUR VEHICLE NOT REQUIRING A PERMIT'
when upper(activity) like 'VRM CHANGED' then 'VRM CHANGED'
when upper(activity) like 'VRM CHANGED FROM%' then 'VRM CHANGED'
when upper(activity) like 'WILL BE REMOVED WITH PAYMENT' then 'REMOVED WITH PAYMENT'
when upper(activity) like '' or upper(activity) like ' ' or upper(activity) is null then
            upper(case 
            when substr(permit_referece,1,3) = 'HYA' then 'All zone'
            when substr(permit_referece,1,3) = 'HYG' then 'Companion Badge'
            when substr(permit_referece,1,3) = 'HYB' then 'Business'
            when substr(permit_referece,1,3) = 'HYD' then 'Doctor'
            when substr(permit_referece,1,3) = 'HYP' then 'Estate resident'
            when substr(permit_referece,1,3) = 'HYH' then 'Health and social care'
            when substr(permit_referece,1,3) = 'HYR' then 'Residents'
            when substr(permit_referece,1,3) = 'HYL' then 'Leisure Centre Permit'
            when substr(permit_referece,1,3) = 'HYE' then 'All Zone Business Voucher'
            when substr(permit_referece,1,3) = 'HYF' then 'Film Voucher'
            when substr(permit_referece,1,3) = 'HYJ' then 'Health and Social Care Voucher'
            when substr(permit_referece,1,3) = 'HYQ' then 'Estate Visitor Voucher'
            when substr(permit_referece,1,3) = 'HYV' then 'Resident Visitor Voucher'
            when substr(permit_referece,1,3) = 'HYN' then 'Dispensation'
            when permit_referece ='HY50300' then 'Dispensation'
            when substr(permit_referece,1,3) = 'HYS' then 'Suspension'
            else substr(permit_referece,1,3)
            end)
end as activity_tag_group


/*Activity Tag*/
,case
when upper(activity) like 'ACTIVATE VOUCHER MAIL SENT FOR CONFIRMATION.' then 'ACTIVATE VOUCHER MAIL SENT FOR CONFIRMATION'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: A JOB DESCRIPTION FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: A JOB DESCRIPTION FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE BACK FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE BACK FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE FRONT FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: BLUE BADGE FRONT FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: CORPORATE TAX OR VAT RETURN FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: CORPORATE TAX OR VAT RETURN FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: DOCUMENTATION REQUESTED BY EMAIL FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: DOCUMENTATION REQUESTED BY EMAIL FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: DRIVING LICENCE FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: DRIVING LICENCE FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: LETTER FROM RELEVANT RELIGIOUS LEADER FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: LETTER FROM RELEVANT RELIGIOUS LEADER FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: LETTER FROM YOUR ORGANISATION, SIGNED BY YOUR LINE MANAGER IN SUPPORT OF PERMIT APPLICANT%' then 'ADDITIONAL EVIDENCE REQUESTED: LETTER FROM YOUR ORGANISATION, SIGNED BY YOUR LINE MANAGER IN SUPPORT OF PERMIT APPLICANT'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: LGP CONVERSION CERTIFICATE FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: LGP CONVERSION CERTIFICATE FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: REMOVAL COMPANY DETAILS FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: REMOVAL COMPANY DETAILS FROM CUSTOMER'
when upper(activity) like 'ADDITIONAL EVIDENCE REQUESTED: VEHICLE LOG BOOK FROM CUSTOMER%' then 'ADDITIONAL EVIDENCE REQUESTED: VEHICLE LOG BOOK FROM CUSTOMER'
when upper(activity) like 'APPLICATION SENT TO ASSISTANT DIRECTOR%' then 'APPLICATION SENT TO ASSISTANT DIRECTOR'
when upper(activity) like 'BOOK VOUCHER MAIL SENT FOR CONFIRMATION.' then 'BOOK VOUCHER MAIL SENT FOR CONFIRMATION' --Book voucher mail sent for confirmation.
when upper(activity) like 'CANCEL VOUCHER MAIL SENT FOR CONFIRMATION.' then 'CANCEL VOUCHER MAIL SENT FOR CONFIRMATION'
when upper(activity) like 'CHANGE ADDRESS REQUEST HAS BEEN REJECTED.' then 'CHANGE ADDRESS REQUEST HAS BEEN REJECTED'
when upper(activity) like 'CHANGED PERMIT VRM%' then 'CHANGED PERMIT VRM'
when upper(activity) like 'CITYPAY REFUND PROCESSED, REFUND' then 'CITYPAY REFUND PROCESSED, REFUND'
when upper(activity) like 'CITYPAY REFUND PROCESSED, REFUND % FAILED%' then 'CITYPAY REFUND PROCESSED, REFUND FAILED'
when upper(activity) like 'CITYPAY REFUND PROCESSED, REFUND % PROCESSED%' then 'CITYPAY REFUND PROCESSED, REFUND PROCESSED'
when upper(activity) like 'CONFIRMATION OF VOUCHER BOOKING.' then 'CONFIRMATION OF VOUCHER BOOKING'
when upper(activity) like 'CONTACT CENTRE ACTION CREATED%' then 'CONTACT CENTRE ACTION CREATED'
when upper(activity) like 'CONTACT CENTRE ACTION REQUEST FOR PERMIT REFERENCE%' then 'CONTACT CENTRE ACTION REQUEST FOR PERMIT REFERENCE'
when upper(activity) like 'DELETE VOUCHER MAIL SENT FOR CONFIRMATION%' then 'DELETE VOUCHER MAIL SENT FOR CONFIRMATION'
when upper(activity) like 'DISCOUNTED VOUCHER BOOKS REFUNED%' then 'DISCOUNTED VOUCHER BOOKS REFUNED'
when upper(activity) like 'DISPENSATION REMOVED' then 'DISPENSATION REMOVED'
when upper(activity) like 'DISPENSATION VRM REQUIRED REMINDER SENT' then 'DISPENSATION VRM REQUIRED REMINDER SENT'
when upper(activity) like 'E VOUCHER MAIL SENT FOR ACTIVATION.' then 'E VOUCHER MAIL SENT FOR ACTIVATION'
when upper(activity) like 'EMAI OF REJECTION SENT%' then 'EMAIL OF REJECTION SENT'
when upper(activity) like 'EMAIL OF APPROVAL SENT%' then 'EMAIL OF APPROVAL SENT'
when upper(activity) like 'EMAIL OF CANCELLATION SENT%' then 'EMAIL OF CANCELLATION SENT'

when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOU HAVE PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOU HAVE PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOU HAVE UNPAID INVOICES FOR PREVIOUS SUSPENSION(S)' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOU HAVE UNPAID INVOICES FOR PREVIOUS SUSPENSION(S)'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION APPLICATION IS NOT A GENUINE EMERGENCY' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION APPLICATION IS NOT A GENUINE EMERGENCY'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS (SEE BELOW FOR DETAILS)' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS (SEE BELOW FOR DETAILS)'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION WOULD CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION WOULD CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA'
when upper(activity) like 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION WOULD CREATE UNACCEPTABLE PARKING STRESS IN THE AREA' then 'EMAIL OF REJECTION SENT. REASON FOR REJECTION YOUR SUSPENSION WOULD CREATE UNACCEPTABLE PARKING STRESS IN THE AREA'

when upper(activity) like 'EMAIL OF REJECTION SENT%' then 'EMAIL OF REJECTION SENT'
when upper(activity) like 'EMAIL SENT TO FILMING OFFICE%' then 'EMAIL SENT TO FILMING OFFICE' --email sent to Filming office11/04/2017
when upper(activity) like 'EVIDENCE REMINDER SENT' then 'EVIDENCE REMINDER SENT'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 A LETTER FROM YOUR ORGANISATION, SIGNED BY YOUR LINE MANAGER IN SUPPORT OF PERMIT APPLICANT% APPLICATION FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 A LETTER FROM YOUR ORGANISATION, SIGNED BY YOUR LINE MANAGER IN SUPPORT OF PERMIT APPLICANT APPLICATION FROM CUSTOMER' --Evidence requested again: 1 A Letter from your organisation, signed by your line manager in support of permit applicantâ€™s application from Customer for HYH12690247
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (BACK OF BLUE BADGE) FROM CUSTOMER FOR %' then 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (BACK OF BLUE BADGE) FROM CUSTOMER' --Evidence requested again: 1 Blue badge (back of blue badge) from Customer for HYG9063640
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER' --Evidence requested again: 1 Blue badge (front and back of blue badge) from Customer for HYG0999184
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (FRONT OF BLUE BADGE) FROM CUSTOMER FOR %' then 'EVIDENCE REQUESTED AGAIN: 1 BLUE BADGE (FRONT OF BLUE BADGE) FROM CUSTOMER' --Evidence requested again: 1 Blue badge (front of blue badge) from Customer for HYG9303744
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 LPG CONVERSION CERTIFICATE FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 LPG CONVERSION CERTIFICATE FROM CUSTOMER' --Evidence requested again: 1 LPG Conversion Certificate from Customer for HYR1380158
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PERMIT APPLICANT% JOB DESCRIPTION FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 PERMIT APPLICANT JOB DESCRIPTION FROM CUSTOMER' --Evidence requested again: 1 Permit applicantâ€™s job description from Customer for HYH12690247
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF BUSINESS AT THIS ADDRESS FROM CUSTOMER FOR %' then 'EVIDENCE REQUESTED AGAIN: 1 PROOF BUSINESS AT THIS ADDRESS FROM CUSTOMER' --Evidence requested again: 1 proof business at this address from Customer for HYB7312888
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF ADDRESS FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF ADDRESS FROM CUSTOMER' --Evidence requested again: null proof of address from Customer for HYR4946492
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF BUSINESS WORKS FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF BUSINESS WORKS FROM CUSTOMER' --Evidence requested again: 1 proof of business works from Customer for HYN11136834
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF VEHICLE INFORMATION FROM CUSTOMER%' then 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF VEHICLE INFORMATION FROM CUSTOMER' --Evidence requested again: 1 proof of vehicle information from Customer for HYR9942251
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF WEDDING  FROM CUSTOMER%' then 'EVIDENCE REQUESTED AGAIN: 1 PROOF OF WEDDING  FROM CUSTOMER'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (BACK OF BLUE BADGE) FROM CUSTOMER%' then 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (BACK OF BLUE BADGE) FROM CUSTOMER'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER%' then 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (FRONT AND BACK OF BLUE BADGE) FROM CUSTOMER'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (FRONT OF BLUE BADGE) FROM CUSTOMER FOR %' then 'EVIDENCE REQUESTED AGAIN: NULL BLUE BADGE (FRONT OF BLUE BADGE) FROM CUSTOMER' --Evidence requested again: 1 Blue badge (back of blue badge) from Customer for HYG7461744
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL DOCUMENTATION REQUESTED BY EMAIL FROM CUSTOMER FOR %' then 'EVIDENCE REQUESTED AGAIN: NULL DOCUMENTATION REQUESTED BY EMAIL FROM CUSTOMER' --Evidence requested again: null Documentation requested by email from Customer for HYS11582596
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL LPG CONVERSION CERTIFICATE FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: NULL LPG CONVERSION CERTIFICATE FROM CUSTOMER' --Evidence requested again: null LPG Conversion Certificate from Customer for HYP4205978
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL PROOF BUSINESS AT THIS ADDRESS FROM CUSTOMER%' then 'EVIDENCE REQUESTED AGAIN: NULL PROOF BUSINESS AT THIS ADDRESS FROM CUSTOMER'
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL PROOF OF ADDRESS FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: NULL PROOF OF ADDRESS FROM CUSTOMER' --Evidence requested again: null proof of address from Customer for HYG4978685
when upper(activity) like 'EVIDENCE REQUESTED AGAIN: NULL PROOF OF VEHICLE INFORMATION FROM CUSTOMER FOR%' then 'EVIDENCE REQUESTED AGAIN: NULL PROOF OF VEHICLE INFORMATION FROM CUSTOMER' --Evidence requested again: null proof of vehicle information from Customer for HYB5776458
when upper(activity) like 'EXTEND VOUCHER MAIL SENT FOR CONFIRMATION.' then 'EXTEND VOUCHER MAIL SENT FOR CONFIRMATION' --Extend voucher mail sent for confirmation.
when upper(activity) like 'EXTENSION REQUEST IS APPROVED BY : ' then 'EXTENSION REQUEST IS APPROVED BY' --Extension request is approved by : Extension request is approved by :
when upper(activity) like 'EXTENSION REQUEST IS REJECTED: ' then 'EXTENSION REQUEST IS REJECTED:'  --Extension request is rejected: 
when upper(activity) like 'FULL PRICE VOUCHER BOOKS REFUNED' then 'FULL PRICE VOUCHER BOOKS REFUNED'
when upper(activity) like 'FULL PRICE VOUCHER BOOKS REFUNED %. REFUND AMOUNT%' then 'FULL PRICE VOUCHER BOOKS REFUNED' --Full price voucher books refuned 1. Refund amount: £20.50
when upper(activity) like 'MANUAL REFUND PROCESSED, REFUND OF % HAS BEEN PROCESSED ON %' then 'MANUAL REFUND PROCESSED, REFUND' --Manual refund processed, Refund of £7.75 has been processed on 17/11/2022 00:00
when upper(activity) like 'ON LBH INSTRUCTION PERMIT STATUS CHANGED TO ORDER RENEW' then 'ON LBH INSTRUCTION PERMIT STATUS CHANGED TO ORDER RENEW'
when upper(activity) like 'ORDER QUANTITY SET TO%' then 'ORDER QUANTITY SET TO'
when upper(activity) like 'PERMIT ADDRESS WILL BE CHANGED%' then 'PERMIT ADDRESS WILL BE CHANGED'
when upper(activity) like 'PERMIT HAS BEEN PRINTED LOCALLY%' then 'PERMIT HAS BEEN PRINTED LOCALLY'
when upper(activity) like 'PERMIT HAS BEEN SENT FOR PRINTING%' then 'PERMIT HAS BEEN SENT FOR PRINTING'
when upper(activity) like 'PERMIT HAS BEEN SENT FOR VIRTUAL COVER%' then 'PERMIT HAS BEEN SENT FOR VIRTUAL COVER'

when upper(activity) like 'PERMIT RENEWAL REJECTED PAYMENT FAILURE%' then 'PERMIT RENEWAL REJECTED PAYMENT FAILURE'
when upper(activity) like 'PERMIT RENEWAL REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED%' then 'PERMIT RENEWAL REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED' 
when upper(activity) like 'PERMIT RENEWAL REJECTED WITH REFUND%' then 'PERMIT RENEWAL REJECTED WITH REFUND'
when upper(activity) like 'PERMIT RENEWAL REJECTED YOUR APPLICATION NOT MEETING THIS PERMIT%S CRITERIA%' then 'PERMIT RENEWAL REJECTED YOUR APPLICATION NOT MEETING THIS PERMITS CRITERIA'
when upper(activity) like 'PERMIT RENEWAL ACCEPTED%' then 'PERMIT RENEWAL ACCEPTED'
when upper(activity) like 'PERMIT RENEWAL REJECTED%' then 'PERMIT RENEWAL REJECTED'
when upper(activity) like 'PERMIT RENEWED%' then 'PERMIT RENEWED'
when upper(activity) like 'PERMIT STATUS CHANGED' then 'PERMIT STATUS CHANGED' 
when upper(activity) like 'PERMIT STATUS CHANGED TO  ' then 'PERMIT STATUS CHANGED' --Permit status changed to  
when upper(activity) like 'PERMIT STATUS CHANGED TO  APPROVED' then 'PERMIT STATUS CHANGED TO  APPROVED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  CANCELLED' then 'PERMIT STATUS CHANGED TO CANCELLED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  LOST' then 'PERMIT STATUS CHANGED TO LOST'
when upper(activity) like 'PERMIT STATUS CHANGED TO  PERMIT STATUS CHANGED TO LOST %WITH ADMIN FEE PAYMENT OF %' then 'PERMIT STATUS CHANGED TO LOST WITH ADMIN FEE PAYMENT' -- Permit status changed to  Permit status changed to lost  with admin fee payment of Â£10 received 
when upper(activity) like 'PERMIT STATUS CHANGED TO  PERMIT STATUS CHANGED TO DAMAGED  WITH ADMIN FEE PAYMENT' then 'PERMIT STATUS CHANGED TO DAMAGED  WITH ADMIN FEE PAYMENT' 
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED.' OR  upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED' then 'PERMIT STATUS CHANGED TO  REJECTED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF VEHICLE REGISTRATIONS NOT PROVIDED' then 'PERMIT STATUS CHANGED TO REJECTED BECAUSE OF VEHICLE REGISTRATIONS NOT PROVIDED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF REQUESTED EVIDENCE NOT BEING PROVIDED' then 'PERMIT STATUS CHANGED TO REJECTED BECAUSE OF REQUESTED EVIDENCE NOT BEING PROVIDED'  --Permit status changed to  rejected because of requested evidence not being provided
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR APPLICATION NOT MEETING THIS PERMIT%S CRITERIA' then 'PERMIT STATUS CHANGED TO REJECTED BECAUSE OF YOUR APPLICATION NOT MEETING THIS PERMITS CRITERIA'  --Permit status changed to  rejected because of your application not meeting this permit's criteria
when upper(activity) like 'PERMIT STATUS CHANGED TO  RENEWAL - EVIDENCE SUBMITTED%' then 'PERMIT STATUS CHANGED TO  RENEWAL - EVIDENCE SUBMITTED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  STOLEN%' then 'PERMIT STATUS CHANGED TO  STOLEN'
when upper(activity) like 'PERMIT STATUS CHANGED TO  VRM CHANGE%' then 'PERMIT STATUS CHANGED TO  VRM CHANGE'
when upper(activity) like 'PERMIT STATUS CHANGED TO CANCELLED% ' then 'PERMIT STATUS CHANGED TO CANCELLED '
when upper(activity) like 'PERMIT STATUS CHANGED TO LOST%' then 'PERMIT STATUS CHANGED TO LOST'
when upper(activity) like 'PERMIT STATUS CHANGED TO REJECTED AS REQUESTED%' then 'PERMIT STATUS CHANGED TO REJECTED AS REQUESTED'
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF PAYMENT FAILURE' then 'PERMIT STATUS CHANGED TO REJECTED BECAUSE OF PAYMENT FAILURE'  --Permit status changed to  rejected because of payment failure
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR VEHICLE NOT REQUIRING A PERMIT' then 'PERMIT STATUS CHANGED TO REJECTED BECAUSE VEHICLE DOES NOT REQUIRING A PERMIT'   --Permit status changed to  rejected because of your vehicle not requiring a permit
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF THE FILM OFFICE DECLINING THE VOUCHER APPLICATION' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF THE FILM OFFICE DECLINING THE VOUCHER APPLICATION' --Permit status changed to  rejected because of the film office declining the voucher application
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOU HAVING 3 OR MORE OUTSTANDING PCNS THAT REQUIRE PAYMENT' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOU HAVING 3 OR MORE OUTSTANDING PCNS THAT REQUIRE PAYMENT' --Permit status changed to  rejected because of you having 3 or more outstanding PCNs that require payment
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOU NOT LIVING IN THE BOROUGH' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOU NOT LIVING IN THE BOROUGH'  --Permit status changed to  rejected because of you not living in the borough
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING IN A PARKING ZONE' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING IN A PARKING ZONE'  --Permit status changed to  rejected because of your address not being in a parking zone
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING LOCATED WITHIN A CONTROLLED PARKING ZONE IN HACKNEY' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING LOCATED WITHIN A CONTROLLED PARKING ZONE IN HACKNEY'  --Permit status changed to  rejected because of your address not being located within a controlled parking zone in Hackney
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING LOCATED WITHIN THE LONDON BOROUGH OF HACKNEY' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR ADDRESS NOT BEING LOCATED WITHIN THE LONDON BOROUGH OF HACKNEY' --Permit status changed to  rejected because of your address not being located within the London borough of Hackney
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR PERMIT ADDRESS BEING IN A CAR FREE DEVELOPMENT' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR PERMIT ADDRESS BEING IN A CAR FREE DEVELOPMENT'--Permit status changed to  rejected because of your permit address being in a car free development
when upper(activity) like 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS' then 'PERMIT STATUS CHANGED TO  REJECTED BECAUSE OF YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS'--Permit status changed to  rejected because of your vehicle exceeding the maximum dimensions
when upper(activity) like 'PERMIT THEFT REPORT HAS BEEN ACCEPTED FOR REFERENCE%' then 'PERMIT THEFT REPORT HAS BEEN ACCEPTED FOR REFERENCE'
when upper(activity) like 'PERMIT%S CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN ACCEPTED%' then 'PERMITS CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN ACCEPTED'
when upper(activity) like 'PERMIT%S CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN ACCEPTED FOR%' then 'PERMITS CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN ACCEPTED FOR'
when upper(activity) like 'PERMIT%S CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN REJECTED%' then 'PERMITS CHANGE OF VEHICLE DETAILS REQUEST HAS BEEN REJECTED'
when upper(activity) like 'PERSONAL BAY ADDED REFERENCE NUMBER % INSTALLATION DATE%' then 'PERSONAL BAY ADDED REFERENCE NUMBER WITH INSTALLATION DATE' --Personal Bay added Reference Number 00156 Installation Date 9/8/2021
when upper(activity) like 'PERSONAL BAY REMOVED REFERENCE NUMBER % REMOVAL DATE%' then 'PERSONAL BAY REMOVED REFERENCE NUMBER' --Personal Bay removed Reference Number 00013 Removal Date 2/8/2022
when upper(activity) like 'REASON FOR THE REJECTION: YOU HAVE PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL. REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOU HAVE PREVIOUSLY FAILED TO ADHERE TO THE TERMS AND CONDITIONS OF SUSPENSION REQUESTS GRANTED BY HACKNEY COUNCIL. REFUND AMOUNT' --Reason for the rejection: you have previously failed to adhere to the terms and conditions of suspension requests granted by Hackney Council. Refund amount: Â£184.50
when upper(activity) like 'REASON FOR THE REJECTION: YOU HAVE UNPAID INVOICES FOR PREVIOUS SUSPENSION(S). REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOU HAVE UNPAID INVOICES FOR PREVIOUS SUSPENSION(S). REFUND AMOUNT'
when upper(activity) like 'REASON FOR THE REJECTION: YOUR APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION. REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOUR APPLICATION CONTAINS INSUFFICIENT OR CONTRADICTORY INFORMATION. REFUND' --Reason for the rejection: your application contains insufficient or contradictory information. Refund amount: £213.00
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION APPLICATION IS NOT A GENUINE EMERGENCY. REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOUR SUSPENSION APPLICATION IS NOT A GENUINE EMERGENCY. REFUND AMOUNT'
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS (SEE BELOW FOR DETAILS). REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOUR SUSPENSION APPLICATION NEEDS TO BE RE-APPLIED FOR WITH UPDATED DETAILS (SEE BELOW FOR DETAILS)' --Reason for the rejection: your suspension application needs to be re-applied for with updated details (see below for details). Refund amount: £212.50
--Reason for the rejection: your suspension application needs to be re-applied for with updated details (see below for details). Refund amount: £395.50
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION WOULD CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA. REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOUR SUSPENSION WOULD CLASH WITH ANOTHER SUSPENSION IN THE IMMEDIATE AREA. REFUND AMOUNT'
when upper(activity) like 'REASON FOR THE REJECTION: YOUR SUSPENSION WOULD CREATE UNACCEPTABLE PARKING STRESS IN THE AREA. REFUND AMOUNT%' then 'REASON FOR THE REJECTION: YOUR SUSPENSION WOULD CREATE UNACCEPTABLE PARKING STRESS IN THE AREA. REFUND AMOUNT'
when upper(activity) like 'REFUND DUE TO CUSTOMER' then 'REFUND DUE TO CUSTOMER'
when upper(activity) like 'REFUND DUE TO CUSTOMER PERMIT WAS AUTO-APPROVED INCORRECTLY. A FULL REFUND DONE BY MINDMILL MANUALLY.' then 'REFUND DUE TO CUSTOMER PERMIT WAS AUTO-APPROVED INCORRECTLY. A FULL REFUND DONE BY MINDMILL MANUALLY.'
when upper(activity) like 'REFUND WAS SUPRESSED' then 'REFUND WAS SUPRESSED' 
when upper(activity) like 'REFUND OF % WAS SUPRESSED BY %' then 'REFUND WAS SUPRESSED' --Refund of £84.92 was supressed by dmoses
when upper(activity) like 'REFUND OF % DUE TO CUSTOMER' then 'REFUND DUE TO CUSTOMER' --Refund of £20.00 due to customer
when upper(activity) like 'RENEWAL REMINDER SENT TO CUSTOMER FOR PERMIT REFERENCE%' then 'RENEWAL REMINDER SENT TO CUSTOMER FOR PERMIT REFERENCE'
when upper(activity) like 'RENEWAL REMINDER IS NOT SENT FOR PERMIT REFERENCE%' then 'RENEWAL REMINDER IS NOT SENT FOR PERMIT REFERENCE'

when upper(activity) like 'RENEWAL REMINDER SENT TO CUSTOMER%' then 'RENEWAL REMINDER SENT TO CUSTOMER'

when upper(activity) like 'RENEWAL REMINDER SENT' then 'RENEWAL REMINDER SENT'
when upper(activity) like 'ROLE ADDED, USER HAS AN APPROVED HASC ACCOUNT' then 'ROLE ADDED, USER HAS AN APPROVED HASC ACCOUNT'
when upper(activity) like 'SUCCESSFUL APPLICATION WITH PAYMENT%' then 'SUCCESSFUL APPLICATION WITH PAYMENT'
when upper(activity) like 'SUSPENSION' then 'SUSPENSION'
when upper(activity) like '%SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION REFUND IN COST% START AND END DATES ARE%' then 'SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION REFUND IN COST'  -- Suspension amended and approved. Amend suspension refund in cost: £408. Start and end dates are: 2021-05-17 00:00:00.0 and 2021-05-20 00:00:00.0 -- Suspension amended and approved. Amend suspension refund in cost: £170. Start and end dates are: 2021-12-06 00:00:00.0 and 2021-12-10 00:00:00.0
when upper(activity) like '%SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION WITH INCREASE IN COST AND PAYMENT RECEIVED% START AND END DATES ARE%' then 'SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION WITH INCREASE IN COST AND PAYMENT RECEIVED' -- Suspension amended and approved. Amend suspension with increase in cost and payment received: £68. Start and end dates are: 2021-10-12 00:00:00.0 and 2021-10-13 00:00:00.0  -- Suspension amended and approved. Amend suspension with increase in cost and payment received: £136. Start and end dates are: 2021-04-15 00:00:00.0 and 2021-04-18 00:00:00.0

when upper(activity) like '%SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION WITH NO CHANGE IN COST. START AND END DATES ARE%' then 'SUSPENSION AMENDED AND APPROVED. AMEND SUSPENSION WITH NO CHANGE IN COST'  --Suspension amended and approved. Amend suspension with no change in cost. Start and end dates are: 2023-09-11 00:00:00.0 and 2023-09-11 00:00:00.0
when upper(activity) like 'SUSPENSION DUE TO BE CANCELLED ON %. REFUND AMOUNT%' then 'SUSPENSION DUE TO BE CANCELLED WITH REFUND' -- Suspension due to be cancelled on 2022-04-13 00:00:00.0. Refund amount: £114.50
when upper(activity) like 'SUSPENSION DURATION CHANGED. CHANGE DURATION WITH INCREASE IN COST%' then 'SUSPENSION DURATION CHANGED. CHANGE DURATION WITH INCREASE IN COST'
when upper(activity) like '%SUSPENSION DURATION CHANGED. CHANGE DURATION WITH REFUND IN COST:%OLD SUSPENSION START AND END DATES ARE%' then 'SUSPENSION DURATION CHANGED. CHANGE DURATION WITH REFUND IN COST' -- Suspension duration changed. Change duration with refund in cost: Â£102.000. Old suspension start and end dates are : 2020-11-14 00:00:00.0 and 2020-11-15 00:00:00.0 -- Suspension duration changed. Change duration with refund in cost: Â£102.000. Old suspension start and end dates are : 2020-11-14 00:00:00.0 and 2020-11-15 00:00:00.0
when upper(activity) like '%SUSPENSION DURATION CHANGED. OLD SUSPENSION START AND END DATES ARE%' then 'SUSPENSION DURATION CHANGED. OLD SUSPENSION START AND END DATES' -- Suspension duration changed. Old suspension start and end dates are : 2017-04-03 00:00:00.0 and 2017-04-07 00:00:00.0 -- Suspension duration changed. Old suspension start and end dates are : 2017-04-03 00:00:00.0 and 2017-04-07 00:00:00.0
when upper(activity) like 'SUSPENSION EXTENSION APPROVED' then 'SUSPENSION EXTENSION APPROVED' --Suspension extension approved
when upper(activity) like 'SUSPENSION UPDATE TO SIGN UP' then 'SUSPENSION UPDATE TO SIGN UP'
when upper(activity) like 'SUSPENSION UPDATE TO SUSPENSION REJECT' then 'SUSPENSION UPDATE TO SUSPENSION REJECT'
when upper(activity) like '%SUSPENSION UPDATE TO SUSPENSION APPROVED%' then 'SUSPENSION UPDATE TO SUSPENSION APPROVED' --Suspension update to Suspension Approved

when upper(activity) like 'TEMPORARY PERMIT PRINTED STARTING % ENDING %' then 'TEMPORARY PERMIT PRINTED' --Temporary permit printed starting 04/05/2017 ending 04/06/2017
when upper(activity) like 'THE CRIME REFERENCE NUMBER HAS NOT BEEN CONFIRMED BY THE POLICE AND SO A FREE REPLACEMENT IS NOT POSSIBLE FOR REFERENCE%' then 'THE CRIME REFERENCE NUMBER HAS NOT BEEN CONFIRMED BY THE POLICE AND SO A FREE REPLACEMENT IS NOT POSSIBLE FOR REFERENCE'
when upper(activity) like 'THE PROTECTED VEHICLE WAS CHANGED%' then 'THE PROTECTED VEHICLE WAS CHANGED'
when upper(activity) like 'THE SUSPENSION MANUALLY SIGN HAS BEEN UPDATED. THE IDENTIFIER IS%' then 'THE SUSPENSION MANUALLY SIGN HAS BEEN UPDATED. THE IDENTIFIER IS'
when upper(activity) like 'UPDATE VOUCHER MAIL SENT FOR CONFIRMATION.' then 'UPDATE VOUCHER MAIL SENT FOR CONFIRMATION'
when upper(activity) like 'VEHICLE REGISTRATION NUMBER:%' then 'VEHICLE REGISTRATION NUMBER'
when upper(activity) like 'VEHICLE UPDATED ON PERMIT . OLD VEHILCE DETAILS ARE : VRM%' OR upper(activity) like ' VEHICLE UPDATED ON PERMIT . OLD VEHILCE DETAILS ARE : VRM :%' then 'VEHICLE UPDATED ON PERMIT' -- Vehicle updated on permit . Old vehilce details are : vrm : AO05COH Emission (CO2) : 180 manufacturer : VOLKSWAGEN model : POLO TWIST AUTO. Permit charge were 112.000 --Vehicle updated on permit . Old vehilce details are : vrm : DG11VUM Emission (CO2) : 132 manufacturer : HONDA model : CIVIC TYPE-S I-VTEC S-A. Permit charge were 43.000
when upper(activity) like 'VEHICLES ON DISPENSATION CHANGED FROM NULL%' then 'VEHICLES ON DISPENSATION CHANGED FROM NULL'
when upper(activity) like 'VEHICLES ON DISPENSATION CHANGED%' then 'VEHICLES ON DISPENSATION CHANGED'

when upper(activity) like 'VOUCHER HAS BEEN MARKED AS SENT TO PRINT%' then 'VOUCHER HAS BEEN MARKED AS SENT TO PRINT'
when upper(activity) like 'VOUCHER COVER LETTER HAS BEEN PRINTED' then 'VOUCHER COVER LETTER HAS BEEN PRINTED'

when upper(activity) like 'VOUCHER SENT TO LIBERTY' then 'VOUCHER SENT TO LIBERTY'
when upper(activity) like 'VOUCHER SERIAL NUMBERS UPDATED%' then 'VOUCHER SERIAL NUMBERS UPDATED'
when upper(activity) like 'VOUCHER SESSIONS OVERRIDDEN%' then 'VOUCHER SESSIONS OVERRIDDEN'
when upper(activity) like 'VOUCHER SHIPPED LOCALLY' then 'VOUCHER SHIPPED LOCALLY'
when upper(activity) like 'VRM % WILL BE REMOVED WITH EFFECT FROM%' then 'VRM WILL BE REMOVED WITH EFFECT FROM' --VRM GJ52XEM will be removed with effect from 04/05/2017
when upper(activity) like 'VRM % WILL BE REMOVED WITH REFUND' or upper(activity) like 'VRM % WILL BE REMOVED WITH REFUND OF % WITH EFFECT FROM%' then 'VRM WILL BE REMOVED WITH REFUND' --VRM T321NMH WILL BE REMOVED WITH REFUND OF Â£-181.26 WITH EFFECT FROM 09/02/2024
when upper(activity) like '%VRM CHANGE ACCEPTED%' then 'VRM CHANGE ACCEPTED' --VRM CHANGE ACCEPTED
when upper(activity) like 'VRM CHANGE APPLICATION' then 'VRM CHANGE APPLICATION'
when upper(activity) like 'VRM CHANGE APPLICATION % SENT ON%' OR upper(activity) like 'VRM CHANGE APPLICATION SENT ON%' then 'VRM CHANGE APPLICATION SENT' --Vrm change application Â£null sent on 31/05/2017 --Vrm change application sent on 01/03/2017
when upper(activity) like 'VRM CHANGE APPLICATION WITH PAYMENT OF % SENT ON %' then 'VRM CHANGE APPLICATION WITH PAYMENT' --Vrm change application with payment of £8.96 sent on 19/12/2023
when upper(activity) like 'VRM CHANGE REJECTED PAYMENT FAILURE' then 'VRM CHANGE REJECTED PAYMENT FAILURE'
when upper(activity) like 'VRM CHANGE REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED' then 'VRM CHANGE REJECTED REQUESTED EVIDENCE NOT BEING PROVIDED'
when upper(activity) like 'VRM CHANGE REJECTED YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS' then 'VRM CHANGE REJECTED YOUR VEHICLE EXCEEDING THE MAXIMUM DIMENSIONS'
when upper(activity) like 'VRM CHANGE REJECTED YOUR VEHICLE NOT REQUIRING A PERMIT' then 'VRM CHANGE REJECTED YOUR VEHICLE NOT REQUIRING A PERMIT'
when upper(activity) like 'VRM CHANGED' then 'VRM CHANGED'
when upper(activity) like 'VRM CHANGED FROM%' then 'VRM CHANGED FROM'
when upper(activity) like 'WILL BE REMOVED WITH PAYMENT' then 'WILL BE REMOVED WITH PAYMENT'
when upper(activity) like '' or upper(activity) like ' ' or upper(activity) is null then
            upper(case 
            when substr(permit_referece,1,3) = 'HYA' then 'All zone'
            when substr(permit_referece,1,3) = 'HYG' then 'Companion Badge'
            when substr(permit_referece,1,3) = 'HYB' then 'Business'
            when substr(permit_referece,1,3) = 'HYD' then 'Doctor'
            when substr(permit_referece,1,3) = 'HYP' then 'Estate resident'
            when substr(permit_referece,1,3) = 'HYH' then 'Health and social care'
            when substr(permit_referece,1,3) = 'HYR' then 'Residents'
            when substr(permit_referece,1,3) = 'HYL' then 'Leisure Centre Permit'
            when substr(permit_referece,1,3) = 'HYE' then 'All Zone Business Voucher'
            when substr(permit_referece,1,3) = 'HYF' then 'Film Voucher'
            when substr(permit_referece,1,3) = 'HYJ' then 'Health and Social Care Voucher'
            when substr(permit_referece,1,3) = 'HYQ' then 'Estate Visitor Voucher'
            when substr(permit_referece,1,3) = 'HYV' then 'Resident Visitor Voucher'
            when substr(permit_referece,1,3) = 'HYN' then 'Dispensation'
            when permit_referece ='HY50300' then 'Dispensation'
            when substr(permit_referece,1,3) = 'HYS' then 'Suspension'
            else substr(permit_referece,1,3)
            end)
end as activity_tag

,*  from liberator_permit_activity where import_date = (select max(import_date) from liberator_permit_activity ) and activity_by not like '%@%' --232 users 
--and cast(activity_date as date) > current_date - interval '18' month  --Last 400 days from todays date
--limit 75

)
select 
act_data.fy
,act_data.act_MonthYear
,act_data.act_date
,act_data.act_hour
,act_data.product_type
,act_data.product_category
,act_data.activity_by
,act_data.activity_tag_group
,act_data.activity_tag
--,act_data.activity_id
--,act_data.permit_referece
--,act_data.activity_date
--,act_data.activity
--,act_data.record_created
--,act_data.import_timestamp
,act_data.import_year
,act_data.import_month
,act_data.import_day
,act_data.import_date

/*summary total*/
,count(distinct act_data.activity_id) as num_activity_id

from act_data
where cast(act_data.act_date as date) > current_date - interval '50' month  --Last 50 months from todays date
and upper(activity_by) in ('ADIRIE','BOLUFEYISAN','DMOSES','EUTOMI','LEDWARDS','OOLAGUNJU','PSHAKES','RISLAM','SHMULLA','YNGUYEN','SMCCABE')  

group by 
act_data.fy
,act_data.act_MonthYear
,act_data.act_date
,act_data.act_hour
,act_data.product_type
,act_data.product_category
,act_data.activity_by
,act_data.activity_tag_group
,act_data.activity_tag

,act_data.import_date
,act_data.import_year
,act_data.import_month
,act_data.import_day

order by 
act_data.fy desc
,act_data.act_MonthYear desc
'''
SQLQueryparking_customer_services_permit_activity_users_node1715091122327 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"liberator_permit_activity":AmazonS3liberator_permit_activity_node1715091109305}, transformation_ctx = "SQLQueryparking_customer_services_permit_activity_users_node1715091122327")

# Script generated for node Amazon S3 - parking_customer_services_permit_activity_users
AmazonS3parking_customer_services_permit_activity_users_node1715091127108 = glueContext.getSink(path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_customer_services_permit_activity_users/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=["import_year", "import_month", "import_day", "import_date"], enableUpdateCatalog=True, transformation_ctx="AmazonS3parking_customer_services_permit_activity_users_node1715091127108")
AmazonS3parking_customer_services_permit_activity_users_node1715091127108.setCatalogInfo(catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",catalogTableName="parking_customer_services_permit_activity_users")
AmazonS3parking_customer_services_permit_activity_users_node1715091127108.setFormat("glueparquet", compression="snappy")
AmazonS3parking_customer_services_permit_activity_users_node1715091127108.writeFrame(SQLQueryparking_customer_services_permit_activity_users_node1715091122327)
job.commit()
