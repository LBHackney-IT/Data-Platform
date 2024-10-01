import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    get_glue_env_var,
    get_latest_partitions,
)


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

# Script generated for node Amazon S3 -parking_cycle_hangars_denormalisation
AmazonS3parking_cycle_hangars_denormalisation_node1705433167883 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_cycle_hangars_denormalisation",
    transformation_ctx="AmazonS3parking_cycle_hangars_denormalisation_node1705433167883",
)

# Script generated for node Parking raw zone manual - parking_cycle_hangar_denormalised_backfill
Parkingrawzonemanualparking_cycle_hangar_denormalised_backfill_node1711467992130 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="cycle_hangar_denormalised___backfill",
    transformation_ctx="Parkingrawzonemanualparking_cycle_hangar_denormalised_backfill_node1711467992130",
)

# Script generated for node SQL Query
SqlQuery0 = """
/*
 Summary data from "dataplatform-prod-liberator-refined-zone".parking_cycle_hangars_denormalisation
 Filtered by (import_day = '01') First of every month
 and ( upper(in_service) like 'Y') Hangar is in service
 and ( allocation_status like 'live') allocation is live

26/03/2024 - added backfill data parking_cycle_hangar_denormalised_backfill

*/

with cycle_den as (
select distinct --*
parking_cycle_hangar_denormalised_backfill.id
,parking_cycle_hangar_denormalised_backfill.hanger_id
,parking_cycle_hangar_denormalised_backfill.key_id
,parking_cycle_hangar_denormalised_backfill.space
,parking_cycle_hangar_denormalised_backfill.party_id
,parking_cycle_hangar_denormalised_backfill.key_issued
,parking_cycle_hangar_denormalised_backfill.date_of_allocation
,parking_cycle_hangar_denormalised_backfill.allocation_status
,parking_cycle_hangar_denormalised_backfill.fee_due_date
,parking_cycle_hangar_denormalised_backfill.created_by
,parking_cycle_hangar_denormalised_backfill.title
,parking_cycle_hangar_denormalised_backfill.first_name
,parking_cycle_hangar_denormalised_backfill.surname
,parking_cycle_hangar_denormalised_backfill.address1
,parking_cycle_hangar_denormalised_backfill.address2
,parking_cycle_hangar_denormalised_backfill.address3
,parking_cycle_hangar_denormalised_backfill.postcode
,parking_cycle_hangar_denormalised_backfill.telephone_number
,parking_cycle_hangar_denormalised_backfill.email_address
,parking_cycle_hangar_denormalised_backfill.hangar_type
,parking_cycle_hangar_denormalised_backfill.in_service
,parking_cycle_hangar_denormalised_backfill.maintenance_key
,parking_cycle_hangar_denormalised_backfill.spaces
,parking_cycle_hangar_denormalised_backfill.hangar_location
,parking_cycle_hangar_denormalised_backfill.usrn
,parking_cycle_hangar_denormalised_backfill.latitude
,parking_cycle_hangar_denormalised_backfill.longitude
,parking_cycle_hangar_denormalised_backfill.start_of_life
,parking_cycle_hangar_denormalised_backfill.end_of_life
,parking_cycle_hangar_denormalised_backfill.import_year_original	as import_year
,parking_cycle_hangar_denormalised_backfill.import_month_original	as import_month
,case when parking_cycle_hangar_denormalised_backfill.import_day_original like '1' then '01' else parking_cycle_hangar_denormalised_backfill.import_day_original end as import_day
,parking_cycle_hangar_denormalised_backfill.import_date_original as 	import_date
--parking_cycle_hangar_denormalised_backfill.import_datetime
--parking_cycle_hangar_denormalised_backfill.import_timestamp
--parking_cycle_hangar_denormalised_backfill.import_year	as import_year_backfill
--parking_cycle_hangar_denormalised_backfill.import_month as	import_month_backfill
--parking_cycle_hangar_denormalised_backfill.import_day as	import_day_backfill
--parking_cycle_hangar_denormalised_backfill.import_date as import_date_backfill
from parking_cycle_hangar_denormalised_backfill --where import_date = (select max(import_date) from "parking-raw-zone-manual".parking_cycle_hangar_denormalised_backfill) --78,148 --83,742  --5,594  before distinct --78,340 --83,742  83,934  5,594  - with import day filter 60,681 --72,394
 where parking_cycle_hangar_denormalised_backfill.import_day_original = '1'
 and upper(parking_cycle_hangar_denormalised_backfill.in_service) like 'Y'
 and parking_cycle_hangar_denormalised_backfill.allocation_status like 'live'

union all

select --*
cast(id as string) as id
,hanger_id
,key_id
,space
,party_id
,key_issued
,date_of_allocation
,allocation_status
,fee_due_date
,created_by
,title
,first_name
,surname
,address1
,address2
,address3
,postcode
,telephone_number
,email_address
,hangar_type
,in_service
,maintenance_key
,spaces
,hangar_location
,usrn
,latitude
,longitude
,start_of_life
,end_of_life
,import_year
,import_month
,import_day
,import_date

from parking_cycle_hangars_denormalisation
 where parking_cycle_hangars_denormalisation .import_day = '01'
 and upper(parking_cycle_hangars_denormalisation.in_service) like 'Y'
 and parking_cycle_hangars_denormalisation.allocation_status like 'live'

 )


select
to_date(cycle_den.import_date, 'yyyyMMdd') as importdate
,cycle_den.import_date as original_import_date
,cycle_den.hanger_id
,cycle_den.hangar_type
,cycle_den.hangar_location

/*Days to renew*/
,sum(case when (datediff( cast(substr(cycle_den.fee_due_date, 1, 10) as date) , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)   )) < 366 then 1 end) as allocate_due_within_one_year
,sum(case when (datediff( cast(substr(cycle_den.fee_due_date, 1, 10) as date) , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)   )) > 365 then 1 end) as allocate_due_more_than_one_year
,sum(case when (datediff( cast(substr(cycle_den.fee_due_date, 1, 10) as date) , current_date  )) < 366 then 1 end) as due_within_one_year
,sum(case when (datediff( cast(substr(cycle_den.fee_due_date, 1, 10) as date) , current_date  )) > 365 then 1 end) as due_more_than_one_year

,sum(case when  cast(substr(cycle_den.fee_due_date, 1, 10) as date) > current_date then 1 end) as number_due_after_current_date
,sum(case when  cast(substr(cycle_den.fee_due_date, 1, 10) as date) < current_date then 1 end) as number_due_before_current_date

/*period hangar held breakdown years*/

,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > -0 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 366 then 1 end) as held_1_less_one_year
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 365 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 731 then 1 end) as held_2_two_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 730 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 1096 then 1 end) as held_3_three_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 1095 and datediff(  current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 1461 then 1 end) as held_4_four_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 1460 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 1826 then 1 end) as held_5_five_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 1825 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  <  2191 then 1 end) as held_6_six_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 2190 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 2556 then 1 end) as held_7_seven_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 2555 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 2921 then 1 end) as held_8_eight_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 2920 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 3286 then 1 end) as held_9_nine_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 3285 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 3651 then 1 end) as held_10_Ten_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 3650 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 4016 then 1 end) as held_11_eleven_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 4015 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 4381 then 1 end) as held_12_twelve_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 4380 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 4746 then 1 end) as held_13_thirteen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 4745 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 5111 then 1 end) as held_14_fourteen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 5110 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 5476 then 1 end) as held_15_fifteen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 5475 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 5841 then 1 end) as held_16_sixteen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 5840 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 6206 then 1 end) as held_17_seventeen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 6205 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 6571 then 1 end) as held_18_eighteen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 6570 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 6936 then 1 end) as held_19_nineteen_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 6935 and datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  )  < 7301 then 1 end) as held_20_twenty_years
,sum(case when datediff(   current_date , cast(substr(cycle_den.date_of_allocation, 1, 10) as date)  ) > 7300  then 1 end) as held_21_twentyOnePlus_years

/*number of records*/
,count(cycle_den.space) as num_space, count(*) as num_recs -- spaces,
,COUNT(distinct cycle_den.hanger_id) as number_hangars
,COUNT(distinct cycle_den.hanger_id)*6 as hangar_capacity

/*In Service*/
,sum(case when upper(cycle_den.in_service) like 'Y' then 1 end) as flag_in_service


/*key issued*/
,sum(case when upper(cycle_den.key_issued) like 'Y' then 1 end) as number_key_issued
,sum(case when upper(cycle_den.key_issued) like 'N' then 1 end) as number_Key_not_issued

/*Allocation Status*/
,sum(case when cycle_den.allocation_status like 'live' then 1 end) as number_allocation_status_live

/*Renters*/
,count(distinct cycle_den.party_id) as number_party_ids

,count(distinct cycle_den.email_address) as number_email_address


/*Key IDs*/
,count(distinct cycle_den.key_id) as number_diff_key_ids
,count(cycle_den.key_id) as number_key_ids


/*spaces*/
,count(cycle_den.space) as number_space
,count(distinct cycle_den.space) as number_diff_space_letters

/*locations*/
,count(distinct cycle_den.hangar_location) as number_diff_hangar_locations
,count(cycle_den.hangar_location) as number_hangar_locations

/*hangar types*/
,count(distinct cycle_den.hangar_type) as number_diff_hangar_type
,count(cycle_den.hangar_type) as number_hangar_type

/*for partiion*/

,date_format(current_date, 'yyyy') AS import_year
,date_format(current_date, 'MM') AS import_month
,date_format(current_date, 'dd') AS import_day
,date_format(current_date, 'yyyyMMdd') AS import_date

 from cycle_den
 where cycle_den.import_day = '01' or  cycle_den.import_day = '1'
 and upper(cycle_den.in_service) like 'Y'
 and cycle_den.allocation_status like 'live'

group by
cycle_den.import_date
,cycle_den.hanger_id
,cycle_den.hangar_type
,cycle_den.hangar_location
,date_format(current_date, 'yyyyMMdd')
"""
SQLQuery_node1705433170442 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_cycle_hangars_denormalisation": AmazonS3parking_cycle_hangars_denormalisation_node1705433167883,
        "parking_cycle_hangar_denormalised_backfill": Parkingrawzonemanualparking_cycle_hangar_denormalised_backfill_node1711467992130,
    },
    transformation_ctx="SQLQuery_node1705433170442",
)

# Script generated for node Amazon S3 - parking_cycle_hangars_denormalised_inservice_live_gds
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/parking_cycle_hangars_denormalised_inservice_live_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405",
)
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_cycle_hangars_denormalised_inservice_live_gds",
)
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405.setFormat(
    "glueparquet", compression="snappy"
)
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405.writeFrame(
    SQLQuery_node1705433170442
)
job.commit()
