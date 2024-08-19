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

# Script generated for node Amazon S3 liberator-raw-zone - liberator_permit_llpg
AmazonS3liberatorrawzoneliberator_permit_llpg_node1720617252559 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-raw-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="liberator_permit_llpg", transformation_ctx="AmazonS3liberatorrawzoneliberator_permit_llpg_node1720617252559")

# Script generated for node Amazon S3 - liberator-refined-zone - parking_voucher_de_normalised
AmazonS3liberatorrefinedzoneparking_voucher_de_normalised_node1720617253376 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-liberator-refined-zone", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="parking_voucher_de_normalised", transformation_ctx="AmazonS3liberatorrefinedzoneparking_voucher_de_normalised_node1720617253376")

# Script generated for node Amazon S3 - raw-zone-unrestricted-address-api - unrestricted_address_api_dbo_hackney_address
AmazonS3rawzoneunrestrictedaddressapiunrestricted_address_api_dbo_hackney_address_node1720617251032 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-raw-zone-unrestricted-address-api", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="unrestricted_address_api_dbo_hackney_address", transformation_ctx="AmazonS3rawzoneunrestrictedaddressapiunrestricted_address_api_dbo_hackney_address_node1720617251032")

# Script generated for node Amazon S3 - unrestricted_address_api_dbo_hackney_xref
AmazonS3unrestricted_address_api_dbo_hackney_xref_node1724073104086 = glueContext.create_dynamic_frame.from_catalog(database="dataplatform-"+environment+"-raw-zone-unrestricted-address-api", push_down_predicate="to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)", table_name="unrestricted_address_api_dbo_hackney_xref", transformation_ctx="AmazonS3unrestricted_address_api_dbo_hackney_xref_node1724073104086")

# Script generated for node SQL Query
SqlQuery0 = '''
/*
03/07/2024 - updated vouchers approved version two
09/07/2024 - breakdown by household, street, zone, lbh versions.  This is the CPZ version
19/08/2024 - added car free calculations

Source tables:
"dataplatform-stg-liberator-refined-zone".parking_voucher_de_normalised
"dataplatform-stg-liberator-raw-zone".liberator_permit_llpg
"dataplatform-stg-raw-zone-unrestricted-address-api".unrestricted_address_api_dbo_hackney_address
"dataplatform-stg-raw-zone-unrestricted-address-api".unrestricted_address_api_dbo_hackney_xref

*/
with vou as (
Select distinct
cast(concat(substr(Cast(parking_voucher_de_normalised.application_date as varchar(10)),1, 7), '-01') as date) as month_year_application_date
-- cast(to_date(Substr("liberator_raw_zone".parking_voucher_de_normalised.application_date, 1,7), '%Y-%m') as date) as month_year_application_date

,Case
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2031-03-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2031-02-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2031-01-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-12-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-11-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-10-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-09-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-08-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-07-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-06-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-05-%'  THEN '2030'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-04-%'  THEN '2030'--2030
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-03-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-02-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2030-01-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-12-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-11-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-10-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-09-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-08-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-07-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-06-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-05-%'  THEN '2029'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-04-%'  THEN '2029'--2029
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-03-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-02-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2029-01-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-12-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-11-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-10-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-09-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-08-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-07-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-06-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-05-%'  THEN '2028'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-04-%'  THEN '2028'--2028
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-03-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-02-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2028-01-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-12-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-11-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-10-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-09-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-08-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-07-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-06-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-05-%'  THEN '2027'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-04-%'  THEN '2027'--2027
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-03-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-02-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2027-01-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-12-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-11-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-10-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-09-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-08-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-07-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-06-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-05-%'  THEN '2026'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-04-%'  THEN '2026'--2026
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-03-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-02-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2026-01-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-12-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-11-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-10-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-09-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-08-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-07-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-06-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-05-%'  THEN '2025'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-04-%'  THEN '2025'--2025
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-03-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-02-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2025-01-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-12-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-11-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-10-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-09-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-08-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-07-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-06-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-05-%'  THEN '2024'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-04-%'  THEN '2024'--2024
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-03-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-02-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2024-01-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-12-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-11-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-10-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-09-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-08-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-07-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-06-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-05-%'  THEN '2023'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-04-%'  THEN '2023'--2023
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-03-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-02-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2023-01-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-12-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-11-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-10-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-09-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-08-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-07-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-06-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-05-%'  THEN '2022'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-04-%'  THEN '2022'--2022
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-03-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-02-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2022-01-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-12-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-11-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-10-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-09-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-08-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-07-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-06-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-05-%'  THEN '2021'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-04-%'  THEN '2021'--2021
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-03-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-02-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2021-01-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-12-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-11-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-10-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-09-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-08-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-07-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-06-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-05-%'  THEN '2020'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-04-%'  THEN '2020'--2020
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-03-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-02-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2020-01-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-12-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-11-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-10-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-09-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-08-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-07-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-06-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-05-%'  THEN '2019'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-04-%'  THEN '2019'--2019
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-03-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-02-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2019-01-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-12-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-11-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-10-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-09-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-08-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-07-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-06-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-05-%'  THEN '2018'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-04-%'  THEN '2018'--2018
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-03-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-02-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2018-01-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-12-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-11-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-10-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-09-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-08-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-07-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-06-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-05-%'  THEN '2017'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-04-%'  THEN '2017'--2017
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-03-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-02-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2017-01-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-12-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-11-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-10-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-09-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-08-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-07-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-06-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-05-%'  THEN '2016'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-04-%'  THEN '2016'--2016
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-03-%'  THEN '2015'
when cast(parking_voucher_de_normalised.application_date as varchar(10)) like '2016-02-%'  THEN '2015'--2015
else '1900'
end as fy

,case when parking_voucher_de_normalised.cpz !='' and parking_voucher_de_normalised.cpz_name != '' then concat(parking_voucher_de_normalised.cpz,' - ', parking_voucher_de_normalised.cpz_name)
when parking_voucher_de_normalised.cpz !='' and parking_voucher_de_normalised.cpz_name = '' then parking_voucher_de_normalised.cpz
when parking_voucher_de_normalised.cpz ='' and parking_voucher_de_normalised.cpz_name != '' then parking_voucher_de_normalised.cpz_name
else 'NONE'
end as zone_name

,to_date(cast(concat(substr(Cast(parking_voucher_de_normalised.application_date as varchar(10)),1, 7), '-01') as date), 'MMM YYYY') as mon_yr_app_date

/*Approval status*/
,case when upper(parking_voucher_de_normalised.status) in ('APPROVED','ORDER_APPROVED','PENDING_VRM_CHANGE','CREATED','PENDING_ADDR_CHANGE','PAYMENT_RECEIVED','RENEWED') THEN 1 ELSE 0 END as approved_status_flag

/*Voucher Type and groupings*/
,parking_voucher_de_normalised.permit_type as voucher_period
,substr(parking_voucher_de_normalised.voucher_ref,1,3) as PermitType
,case
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYA' then 'All zone'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYG' then 'Companion Badge'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYB' then 'Business'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYD' then 'Doctor'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYP' then 'Estate resident'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYH' then 'Health and social care'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYR' then 'Residents'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYL' then 'Leisure Centre Permit'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYE' then 'All Zone Business Voucher'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYF' then 'Film Voucher'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYJ' then 'Health and Social Care Voucher'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYQ' then 'Estate Visitor Voucher'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) = 'HYV' then 'Resident Visitor Voucher'
 when substr(parking_voucher_de_normalised.voucher_ref,1,3) ='HYN' then 'Dispensation'
 when parking_voucher_de_normalised.voucher_ref ='HY50300' then 'Dispensation'
 else substr(parking_voucher_de_normalised.voucher_ref,1,3)
 end as permit_type_category

,Case when substr(parking_voucher_de_normalised.voucher_ref,1,3) ='HYE' then 'Voucher'
when substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYF' then 'Voucher'
when substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYQ' then 'Voucher'
when substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYV' then 'Voucher'
when substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYJ' then 'Voucher'
when substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYN' then 'Dispensation'
when parking_voucher_de_normalised.voucher_ref ='HY50300' then 'Dispensation'
when substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYS' then 'Suspension' else 'Permit'
end as product_category

,case when (substr(parking_voucher_de_normalised.voucher_ref,1,3) ='HYE' or 
 substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYF'or
substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYQ' or
substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYV' or
substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYJ' ) and parking_voucher_de_normalised.e_voucher ='E' then 'eVoucher'
when (substr(parking_voucher_de_normalised.voucher_ref,1,3) ='HYE' or 
 substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYF'or
substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYQ' or
substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYV' or
substr(parking_voucher_de_normalised.voucher_ref,1,3)='HYJ' ) and
 parking_voucher_de_normalised.e_voucher <> 'E' then 'Paper Voucher' else 'Not Voucher' end as voucher_type_category

/*Calculation of total vouchers in books*/
,cast(case 
when upper(permit_type) like '2 HOUR VISITORS VOUCHERS' and (quantity is not null or quantity not like '' or quantity not like ' ') THEN 20 *  try_cast(quantity as double) --2 hour visitors vouchers x20
when upper(permit_type) like '1 DAY VISITORS VOUCHERS' and  (quantity is not null or quantity not like '' or quantity not like ' ')  THEN 5 *  try_cast(quantity as double) --1 day visitors vouchers x5
when upper(permit_type) like 'FILM VOUCHER' and (quantity is not null or quantity not like '' or quantity not like ' ') THEN 10 *  try_cast(quantity as double) --Film voucher x10
when upper(permit_type) like 'ESTATE VISITOR VOUCHERS' and  (quantity is not null or quantity not like '' or quantity not like ' ')  THEN 10 *  try_cast(quantity as double) --Estate Visitor Vouchers x10
when upper(permit_type) like 'HEALTH AND SOCIAL CARE VOUCHER' and (quantity is not null or quantity not like '' or quantity not like ' ') THEN 5 *  try_cast(quantity as double) --Health and Social Care Voucher x5
when upper(permit_type) like 'ALL ZONE BUSINESS VOUCHER' and  (quantity is not null or quantity not like '' or quantity not like ' ')  THEN 10 *  try_cast(quantity as double) --All Zone Business Voucher x10
end as decimal (10,0)) as total_num_vouchers_in_book
,* 
from parking_voucher_de_normalised where import_date = (Select max(import_date) from parking_voucher_de_normalised ) --544,689

)
, street as (select  
    UPRN as SR_UPRN,
	ADDRESS1 as SR_ADDRESS1,
	ADDRESS2 as SR_ADDRESS2,
	ADDRESS3 as SR_ADDRESS3,
	ADDRESS4 as SR_ADDRESS4,
	ADDRESS5 as SR_ADDRESS5,
	POST_CODE as SR_POST_CODE,
	BPLU_CLASS as SR_BPLU_CLASS,
	X as SR_X,
	Y as SR_Y,
	LATITUDE as SR_LATITUDE,
	LONGITUDE as SR_LONGITUDE,
	IN_CONGESTION_CHARGE_ZONE as SR_IN_CONGESTION_CHARGE_ZONE,
	CPZ_CODE as SR_CPZ_CODE,
	CPZ_NAME as SR_CPZ_NAME,
	LAST_UPDATED_STAMP as SR_LAST_UPDATED_STAMP,
	LAST_UPDATED_TX_STAMP as SR_LAST_UPDATED_TX_STAMP,
	CREATED_STAMP as SR_CREATED_STAMP,
	CREATED_TX_STAMP as SR_CREATED_TX_STAMP,
	HOUSE_NAME as SR_HOUSE_NAME,
	POST_CODE_PACKED as SR_POST_CODE_PACKED,
	STREET_START_X as SR_STREET_START_X,
	STREET_START_Y as SR_STREET_START_Y,
	STREET_END_X as SR_STREET_END_X,
	STREET_END_Y as SR_STREET_END_Y,
	WARD_CODE as SR_WARD_CODE,
if(WARD_CODE = 'E05009367',    'BROWNSWOOD WARD',    
if(WARD_CODE = 'E05009368',    'CAZENOVE WARD',    
if(WARD_CODE = 'E05009369',    'CLISSOLD WARD',    
if(WARD_CODE = 'E05009370',    'DALSTON WARD',    
if(WARD_CODE = 'E05009371',    'DE BEAUVOIR WARD',    
if(WARD_CODE = 'E05009372',    'HACKNEY CENTRAL WARD',    
if(WARD_CODE = 'E05009373',    'HACKNEY DOWNS WARD',    
if(WARD_CODE = 'E05009374',    'HACKNEY WICK WARD',    
if(WARD_CODE = 'E05009375',    'HAGGERSTON WARD',    
if(WARD_CODE = 'E05009376',    'HOMERTON WARD',    
if(WARD_CODE = 'E05009377',    'HOXTON EAST AND SHOREDITCH WARD',    
if(WARD_CODE = 'E05009378',    'HOXTON WEST WARD',    
if(WARD_CODE = 'E05009379',    'KINGS PARK WARD',    
if(WARD_CODE = 'E05009380',    'LEA BRIDGE WARD',    
if(WARD_CODE = 'E05009381',    'LONDON FIELDS WARD',    
if(WARD_CODE = 'E05009382',    'SHACKLEWELL WARD',    
if(WARD_CODE = 'E05009383',    'SPRINGFIELD WARD',    
if(WARD_CODE = 'E05009384',    'STAMFORD HILL WEST',    
if(WARD_CODE = 'E05009385',    'STOKE NEWINGTON WARD',    
if(WARD_CODE = 'E05009386',    'VICTORIA WARD',    
if(WARD_CODE = 'E05009387',    'WOODBERRY DOWN WARD',WARD_CODE))))))))))))))))))))) as SR_ward_name, 	 
	PARISH_CODE as SR_PARISH_CODE,
	PARENT_UPRN as SR_PARENT_UPRN,
	PAO_START as SR_PAO_START,
	PAO_START_SUFFIX as SR_PAO_START_SUFFIX,
	PAO_END as SR_PAO_END,
	PAO_END_SUFFIX as SR_PAO_END_SUFFIX,
	PAO_TEXT as SR_PAO_TEXT,
	SAO_START as SR_SAO_START,
	SAO_START_SUFFIX as SR_SAO_START_SUFFIX,
	SAO_END as SR_SAO_END,
	SAO_END_SUFFIX as SR_SAO_END_SUFFIX,
	SAO_TEXT as SR_SAO_TEXT,
	DERIVED_BLPU as SR_DERIVED_BLPU,
	USRN
,import_year
,import_month
,import_day
,import_date
FROM liberator_permit_llpg
where (ADDRESS1 like 'Street Record' or ADDRESS1 like 'STREET RECORD') and liberator_permit_llpg.import_date = (SELECT MAX(liberator_permit_llpg.import_date) FROM liberator_permit_llpg)
)
, llpg as (
  SELECT * FROM unrestricted_address_api_dbo_hackney_address where unrestricted_address_api_dbo_hackney_address.import_date = (SELECT max(unrestricted_address_api_dbo_hackney_address.import_date) FROM unrestricted_address_api_dbo_hackney_address) and lpi_logical_status like 'Approved Preferred'
  )
, cfxref as (
select * from  unrestricted_address_api_dbo_hackney_xref where import_date = (select max(import_date)  from  unrestricted_address_api_dbo_hackney_xref) and xref_name like 'Parking Blacklisted S106' 
)

select distinct 

vou.fy
,vou.cpz
,vou.cpz_name
,vou.zone_name
,vou.mon_yr_app_date
,vou.month_year_application_date
,vou.approved_status_flag
,vou.permit_type_category
,vou.voucher_period
,vou.PermitType--voucherType --as permittype
,vou.product_category
,vou.voucher_type_category

/*Partitions*/
,   vou.import_year
,	vou.import_month
,	vou.import_day
,	vou.import_date


/*Counters*/

/*Transactions*/
,count(concat(vou.application_date,vou.email_address_of_applicant)) as num_unique_transaction_ref
,count(distinct concat(vou.application_date,vou.email_address_of_applicant)) as num_distinct_unique_transaction_ref

/*Email addresses*/
,count(vou.email_address_of_applicant) as num_email_address_ref
,count(distinct vou.email_address_of_applicant) as num_distinct_email_address_ref

/*CPZ - Zone*/
,count(distinct vou.cpz) as num_distinct_cpz

,count(distinct vou.cpz_name) as num_distinct_cpz_name

,count(distinct vou.zone_name) as num_distinct_zone_name

/*Street(USRN), Ward and Household(UPRN)*/
,count(distinct SR_ADDRESS2) as num_distinct_street_name
,count(distinct SR_WARD_CODE) as num_distinct_street_ward_name
,count(distinct vou.uprn) as num_distinct_uprn_households
,count(distinct street.usrn) as num_distinct_usrn

/*Books, Bookings and Vouchers*/
,cast(sum(try_cast(vou.quantity as double)) as decimal(15,0)) as total_quantity_books
,cast(sum(try_cast(vou.total_num_vouchers_in_book as double)) as decimal(15,0)) as total_num_vouchers_in_books
,cast(sum(try_cast(vou.noofbookings as double)) as decimal(15,0)) as total_num_ebookings
,cast(sum(try_cast(vou.numberofevouchersinsession as double)) as decimal(15,0)) as total_num_evouchers_in_session

/*Income - Total Paid*/
,cast(sum(try_cast(vou.amount as double)) as decimal(15,2)) as total_amount_paid


/*Car Free blacklisted properties counters*/

/*Transactions Car Free*/
,count(  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  concat(vou.application_date,vou.email_address_of_applicant) end) as num_unique_transaction_ref_cfxref
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  concat(vou.application_date,vou.email_address_of_applicant) end) as num_distinct_unique_transaction_ref_cfxref

/*Email addresses Car Free*/
,count( case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  vou.email_address_of_applicant end) as num_email_address_ref
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  vou.email_address_of_applicant end) as num_distinct_email_address_ref_cfxref

/*CPZ - Zone Car Free*/
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  vou.cpz end) as num_distinct_cpz_cfxref
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  vou.cpz_name end) as num_distinct_cpz_name_cfxref
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  vou.zone_name end) as num_distinct_zone_name_cfxref

/*Street(USRN), Ward and Household(UPRN) Car Free*/
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  SR_ADDRESS2 end) as num_distinct_street_name_cfxref
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  SR_WARD_CODE end) as num_distinct_street_ward_name_cfxref
--,count(distinct vou.uprn) as num_distinct_uprn_households
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then vou.uprn end) as num_distinct_uprn_households_cfxref
,count(distinct  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then street.usrn end) as num_distinct_usrn_cfxref

/*Books, Bookings and Vouchers Car Free*/
,cast(sum(  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  try_cast(vou.quantity as double) end ) as decimal(15,0)) as total_quantity_books_cfxref

,cast(sum(  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  try_cast(vou.total_num_vouchers_in_book as double) end ) as decimal(15,0)) as total_num_vouchers_in_books_cfxref
,cast(sum(  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  try_cast(vou.noofbookings as double) end) as decimal(15,0)) as total_num_ebookings_cfxref
,cast(sum(  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  try_cast(vou.numberofevouchersinsession as double) end ) as decimal(15,0)) as total_num_evouchers_in_session_cfxref

/*Income - Total Paid Car Free*/
,cast(sum(  case when cfxref.uprn is not null or cast(cfxref.uprn as string) != '' then  try_cast(vou.amount as double) end) as decimal(15,2)) as total_amount_paid_cfxref


from vou
left join llpg on cast(llpg.uprn as string) = cast(vou.uprn as string) 
left join street on cast(street.usrn as string) = cast(llpg.usrn as string)
left join cfxref on cast(cfxref.uprn as string) = cast(vou.uprn as string) 

Where 
vou.approved_status_flag = 1

group by
vou.fy
,vou.cpz
,vou.cpz_name
,vou.zone_name
,vou.mon_yr_app_date
,vou.month_year_application_date
,vou.approved_status_flag
,vou.permit_type_category
,vou.voucher_period
,vou.PermitType --voucherType
,vou.product_category
,vou.voucher_type_category

/*Partitions*/
,   vou.import_year
,	vou.import_month
,	vou.import_day
,	vou.import_date

Order by
vou.month_year_application_date desc
,vou.PermitType asc --voucherType asc
,vou.voucher_period asc
,vou.voucher_type_category asc
,vou.cpz
--,vou.cpz_name
--,vou.zone_name
'''
SQLQuery_node1720617258366 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"parking_voucher_de_normalised":AmazonS3liberatorrefinedzoneparking_voucher_de_normalised_node1720617253376, "liberator_permit_llpg":AmazonS3liberatorrawzoneliberator_permit_llpg_node1720617252559, "unrestricted_address_api_dbo_hackney_address":AmazonS3rawzoneunrestrictedaddressapiunrestricted_address_api_dbo_hackney_address_node1720617251032, "unrestricted_address_api_dbo_hackney_xref":AmazonS3unrestricted_address_api_dbo_hackney_xref_node1724073104086}, transformation_ctx = "SQLQuery_node1720617258366")

# Script generated for node Amazon S3 - parking_vouchers_approved_summary_gds
AmazonS3parking_vouchers_approved_summary_gds_node1720617264938 = glueContext.getSink(path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_vouchers_approved_summary_gds/", connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=["import_year", "import_month", "import_day", "import_date"], enableUpdateCatalog=True, transformation_ctx="AmazonS3parking_vouchers_approved_summary_gds_node1720617264938")
AmazonS3parking_vouchers_approved_summary_gds_node1720617264938.setCatalogInfo(catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",catalogTableName="parking_vouchers_approved_summary_gds")
AmazonS3parking_vouchers_approved_summary_gds_node1720617264938.setFormat("glueparquet", compression="snappy")
AmazonS3parking_vouchers_approved_summary_gds_node1720617264938.writeFrame(SQLQuery_node1720617258366)
job.commit()
