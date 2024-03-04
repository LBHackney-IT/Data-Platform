import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, create_pushdown_predicate
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

# Script generated for node S3 bucket - raw_zone - liberator_permit_estate_wl
S3bucketraw_zoneliberator_permit_estate_wl_node1 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_permit_estate_wl",
        transformation_ctx="S3bucketraw_zoneliberator_permit_estate_wl_node1",
        push_down_predicate=create_pushdown_predicate("import_date", 7),
    )
)

# Script generated for node Amazon S3 - parking_permit_denormalised_gds_street_llpg
AmazonS3parking_permit_denormalised_gds_street_llpg_node1640271444228 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_permit_denormalised_gds_street_llpg",
    transformation_ctx="AmazonS3parking_permit_denormalised_gds_street_llpg_node1640271444228",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*Distinct Estate Waiting List with all live permits by permit type

query to calculate number of live permits by type
*/
with lp_type as(
  select 
sum(Case when live_permit_flag = 1 and blue_badge_number !='' and permit_type like 'Estate Resident' and (amount like '0.00' or amount like '0.000'  or amount like '') then 1 else 0 end) as flag_lp_estate_bb_zero
,sum(Case when live_permit_flag = 1 and blue_badge_number !='' and permit_type != 'Estate Resident' then 1 else 0 end) as flag_lp_bb_onstreet

,sum(Case when live_permit_flag = 1 and permit_type like 'Estate Resident' then 1 else 0 end) as flag_lp_estate
,sum(Case when live_permit_flag = 1 and permit_type like 'Business' then 1 else 0 end) as flag_lp_business
,sum(Case when live_permit_flag = 1 and permit_type like 'Doctor' then 1 else 0 end) as flag_lp_doctor
,sum(Case when live_permit_flag = 1 and permit_type like 'Leisure centre permit' then 1 else 0 end) as flag_lp_leisure
,sum(Case when live_permit_flag = 1 and permit_type like 'Health and Social Care' then 1 else 0 end) as flag_lp_hsc
,sum(Case when live_permit_flag = 1 and permit_type like 'Residents' then 1 else 0 end) as flag_lp_residents
,sum(Case when live_permit_flag = 1 and permit_type like 'Dispensation' then 1 else 0 end) as flag_lp_dispensation
,sum(Case when live_permit_flag = 1 and permit_type not in ('Estate Resident','All Zone','Companion Badge','Dispensation','Residents','Health and Social Care','Leisure centre permit','Doctor','Business') then 1 else 0 end) as flag_lp_other
,sum(Case when live_permit_flag = 1 and permit_type like 'All Zone' then 1 else 0 end) as flag_lp_all_zone
,sum(Case when live_permit_flag = 1 and permit_type like 'Companion Badge' then 1 else 0 end) as flag_lp_companion_badge
, sum(live_permit_flag) as live_permit
,uprn, sr_usrn, import_date from parking_permit_denormalised_gds_street_llpg where import_date = (select max(import_date) from parking_permit_denormalised_gds_street_llpg)
  
Group by uprn, sr_usrn, import_date 
  )

/*query to identify and filter max record_created date for each waiting list id*/
, wlmxrec as (SELECT id, concat(substr(Cast(application_date as varchar(10)),1, 7), '-01'), application_date,  max(record_created) as mxrec, import_date  FROM liberator_permit_estate_wl

where import_date = (SELECT max(import_date) FROM liberator_permit_estate_wl)

group by id, application_date, concat(substr(Cast(application_date as varchar(10)),1, 7), '-01'),  import_date
  )

SELECT distinct concat(substr(Cast(liberator_permit_estate_wl.application_date as varchar(10)),1, 7), '-01') as MonthYear
,lp_type.live_permit
,lp_type.flag_lp_estate_bb_zero, lp_type.flag_lp_bb_onstreet, lp_type.flag_lp_estate, lp_type.flag_lp_business, lp_type.flag_lp_doctor, lp_type.flag_lp_leisure, lp_type.flag_lp_hsc, lp_type.flag_lp_residents, lp_type.flag_lp_dispensation, lp_type.flag_lp_other, lp_type.flag_lp_all_zone, lp_type.flag_lp_companion_badge
,case when z_code !='' and estate_name != '' then concat(z_code,' - ', estate_name)
when z_code !='' and estate_name = '' then concat(z_code)
when z_code ='' and estate_name != '' then concat(estate_name)
else 'NONE'
end as zone_name
,case 
when address_line_1 ='' then concat(cast(liberator_permit_estate_wl.id as string),' - ',substr(cast(liberator_permit_estate_wl.application_date as string),1,19),' - ',email)
when address_line_2 ='' then concat(cast(liberator_permit_estate_wl.id as string),' - ',substr(cast(liberator_permit_estate_wl.application_date as string),1,19),' - ',address_line_1,', ',postcode,' - ',email)
when address_line_3 ='' then concat(cast(liberator_permit_estate_wl.id as string),' - ',substr(cast(liberator_permit_estate_wl.application_date as string),1,19),' - ',address_line_1,', ',address_line_2,', ',postcode,' - ',email) 
else concat(cast(liberator_permit_estate_wl.id as string),' - ',substr(cast(liberator_permit_estate_wl.application_date as string),1,19),' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',postcode,' - ',email) 
end as wl_summary


,case 
when address_line_2 ='' then concat(cast(liberator_permit_estate_wl.id as string),' - ',address_line_1,', ',postcode)
when address_line_3 ='' then concat(cast(liberator_permit_estate_wl.id as string),' - ',address_line_1,', ',address_line_2,', ',postcode) 
else concat(cast(liberator_permit_estate_wl.id as string),' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',postcode) 
end as wl_id_full_address
,case 
when address_line_2 ='' then concat(address_line_1,', ',postcode)
when address_line_3 ='' then concat(address_line_1,', ',address_line_2,', ',postcode) 
else concat(address_line_1,', ',address_line_2,', ',address_line_3,', ',postcode) 
end as full_address
,liberator_permit_estate_wl.* FROM liberator_permit_estate_wl

left join lp_type on lp_type.uprn = liberator_permit_estate_wl.uprn and lp_type.import_date = liberator_permit_estate_wl.import_date

left join wlmxrec on wlmxrec.id = liberator_permit_estate_wl.id and wlmxrec.mxrec = liberator_permit_estate_wl.record_created and wlmxrec.import_date = liberator_permit_estate_wl.import_date


where liberator_permit_estate_wl.import_date = (SELECT max(liberator_permit_estate_wl.import_date) FROM liberator_permit_estate_wl) and cast(wlmxrec.mxrec as string) !=''

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_permit_denormalised_gds_street_llpg": AmazonS3parking_permit_denormalised_gds_street_llpg_node1640271444228,
        "liberator_permit_estate_wl": S3bucketraw_zoneliberator_permit_estate_wl_node1,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_estate_waiting_list_live_permits_type_gds/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_estate_waiting_list_live_permits_type_gds",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
