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

# Script generated for node Amazon S3 -parking_cycle_hangars_denormalisation
AmazonS3parking_cycle_hangars_denormalisation_node1705433167883 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    table_name="parking_cycle_hangars_denormalisation",
    transformation_ctx="AmazonS3parking_cycle_hangars_denormalisation_node1705433167883",
)

# Script generated for node SQL Query
SqlQuery0 = """
/*
 Summary data from "dataplatform-prod-liberator-refined-zone".parking_cycle_hangars_denormalisation 
 Filtered by (import_day = '01') First of every month
 and ( upper(in_service) like 'Y') Hangar is in service
 and ( allocation_status like 'live') allocation is live
 
 17/01/2024 - created

*/

select 
to_date(import_date, 'yyyyMMdd') as importdate
,import_date as original_import_date
,hanger_id
,hangar_type
,hangar_location

/*Days to renew*/
,sum(case when (datediff( cast(substr(fee_due_date, 1, 10) as date) , cast(substr(date_of_allocation, 1, 10) as date)   )) < 366 then 1 end) as allocate_due_within_one_year
,sum(case when (datediff( cast(substr(fee_due_date, 1, 10) as date) , cast(substr(date_of_allocation, 1, 10) as date)   )) > 365 then 1 end) as allocate_due_more_than_one_year
,sum(case when (datediff( cast(substr(fee_due_date, 1, 10) as date) , current_date  )) < 366 then 1 end) as due_within_one_year
,sum(case when (datediff( cast(substr(fee_due_date, 1, 10) as date) , current_date  )) > 365 then 1 end) as due_more_than_one_year 

,sum(case when  cast(substr(fee_due_date, 1, 10) as date) > current_date then 1 end) as number_due_after_current_date
,sum(case when  cast(substr(fee_due_date, 1, 10) as date) < current_date then 1 end) as number_due_before_current_date

/*period hangar held breakdown years*/

,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > -0 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 366 then 1 end) as held_1_less_one_year
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 365 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 731 then 1 end) as held_2_two_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 730 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 1096 then 1 end) as held_3_three_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 1095 and datediff(  current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 1461 then 1 end) as held_4_four_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 1460 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 1826 then 1 end) as held_5_five_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 1825 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  <  2191 then 1 end) as held_6_six_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 2190 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 2556 then 1 end) as held_7_seven_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 2555 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 2921 then 1 end) as held_8_eight_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 2920 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 3286 then 1 end) as held_9_nine_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 3285 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 3651 then 1 end) as held_10_Ten_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 3650 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 4016 then 1 end) as held_11_eleven_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 4015 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 4381 then 1 end) as held_12_twelve_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 4380 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 4746 then 1 end) as held_13_thirteen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 4745 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 5111 then 1 end) as held_14_fourteen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 5110 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 5476 then 1 end) as held_15_fifteen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 5475 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 5841 then 1 end) as held_16_sixteen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 5840 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 6206 then 1 end) as held_17_seventeen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 6205 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 6571 then 1 end) as held_18_eighteen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 6570 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 6936 then 1 end) as held_19_nineteen_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 6935 and datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  )  < 7301 then 1 end) as held_20_twenty_years
,sum(case when datediff(   current_date , cast(substr(date_of_allocation, 1, 10) as date)  ) > 7300  then 1 end) as held_21_twentyOnePlus_years

/*number of records*/
,count(space) as num_space, count(*) as num_recs -- spaces,
,COUNT(distinct hanger_id) as number_hangars
,COUNT(distinct hanger_id)*6 as hangar_capacity

/*In Service*/
,sum(case when upper(in_service) like 'Y' then 1 end) as flag_in_service


/*key issued*/
,sum(case when upper(key_issued) like 'Y' then 1 end) as number_key_issued
,sum(case when upper(key_issued) like 'N' then 1 end) as number_Key_not_issued

/*Allocation Status*/
,sum(case when allocation_status like 'live' then 1 end) as number_allocation_status_live

/*Renters*/
,count(distinct party_id) as number_party_ids

,count(distinct email_address) as number_email_address


/*Key IDs*/
,count(distinct key_id) as number_diff_key_ids
,count(key_id) as number_key_ids


/*spaces*/
,count(space) as number_space
,count(distinct space) as number_diff_space_letters

/*locations*/
,count(distinct hangar_location) as number_diff_hangar_locations
,count(hangar_location) as number_hangar_locations

/*hangar types*/
,count(distinct hangar_type) as number_diff_hangar_type
,count(hangar_type) as number_hangar_type

/*for partiion*/

,replace(cast(current_date() as string),'-','') as import_date
,cast(Year(current_date) as string)    as import_year 
,cast(month(current_date) as string)   as import_month 
,cast(day(current_date) as string)     as import_day

	

 from parking_cycle_hangars_denormalisation 
 where import_day = '01' 
 and upper(in_service) like 'Y' 
 and allocation_status like 'live'

group by to_date(import_date, 'yyyymmdd') --as importdate
,import_date
,hanger_id
,hangar_type
,hangar_location
,replace(cast(current_date() as string),'-','') --as import_date
,cast(Year(current_date) as string)    --as import_year 
,cast(month(current_date) as string)   --as import_month 
,cast(day(current_date) as string)     --as import_day
"""
SQLQuery_node1705433170442 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_cycle_hangars_denormalisation": AmazonS3parking_cycle_hangars_denormalisation_node1705433167883
    },
    transformation_ctx="SQLQuery_node1705433170442",
)

# Script generated for node Amazon S3 - parking_cycle_hangars_denormalised_inservice_live_gds
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/parking_cycle_hangars_denormalised_inservice_live_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405",
)
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="parking_cycle_hangars_denormalised_inservice_live_gds",
)
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405.setFormat(
    "glueparquet", compression="snappy"
)
AmazonS3parking_cycle_hangars_denormalised_inservice_live_gds_node1705433173405.writeFrame(
    SQLQuery_node1705433170442
)
job.commit()
