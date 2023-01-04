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

# Script generated for node Amazon S3 - parking_permit_denormalised_gds_street_llpg
AmazonS3parking_permit_denormalised_gds_street_llpg_node1650475071787 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    push_down_predicate="  to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="parking_permit_denormalised_gds_street_llpg",
    transformation_ctx="AmazonS3parking_permit_denormalised_gds_street_llpg_node1650475071787",
)

# Script generated for node Amazon S3 - pcnfoidetails_pcn_foi_full
AmazonS3pcnfoidetails_pcn_foi_full_node1650477300290 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    push_down_predicate="  to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3pcnfoidetails_pcn_foi_full_node1650477300290",
)

# Script generated for node S3 bucket - unrestricted_address_api_dbo_national_address
S3bucketunrestricted_address_api_dbo_national_address_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-raw-zone-unrestricted-address-api",
    push_down_predicate="  to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 30)",
    table_name="unrestricted_address_api_dbo_national_address",
    transformation_ctx="S3bucketunrestricted_address_api_dbo_national_address_node1",
)

# Script generated for node Amazon S3 - unrestricted_address_api_dbo_hackney_address
AmazonS3unrestricted_address_api_dbo_hackney_address_node1650475065696 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-raw-zone-unrestricted-address-api",
    push_down_predicate="  to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 30)",
    table_name="unrestricted_address_api_dbo_hackney_address",
    transformation_ctx="AmazonS3unrestricted_address_api_dbo_hackney_address_node1650475065696",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*PCNs VRM match to Permits VRM with match to LLPG and NLPG for Registered and Current addresses Post Code last 13 months of pcn issue date
tables:
unrestricted_address_api_dbo_national_address
unrestricted_address_api_dbo_hackney_address
"dataplatform-"+environment+"-liberator-refined-zone"."parking_permit_denormalised_gds_street_llpg"
pcnfoidetails_pcn_foi_full

20/04/2022 - created glue job
27/04/2022 - updated to remove duplicate post code from llpg and nlpg lookup tables and pcn addresses with commas removed
08/12/2022 - simpler postcode extracter - regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') 
09/12/2022 - updated postcode extracter to case statement to flag those with no addresses
19/12/2022 - changed no space from regexp_replace to replace for postcode joins and matching
*/

With nlpg_pc_summ_reg as (/*Summary Post Codes National Gazetteer - NLPG*/
    select row_number() over (partition by postcode_nospace order by postcode_nospace desc ) as nlpg_rn_reg ,gazetteer as nlpg_gazetteer_reg /*,locality as nlpg_locality_reg ,ward as nlpg_ward_reg ,town as nlpg_town_reg*/ ,postcode as nlpg_postcode_reg ,postcode_nospace as nlpg_postcode_nospace_reg
        ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as nlpg_area_reg 
    /*,count(*) as nlpg_num_records_reg*/ FROM unrestricted_address_api_dbo_national_address where unrestricted_address_api_dbo_national_address.import_date = (SELECT max(unrestricted_address_api_dbo_national_address.import_date) FROM unrestricted_address_api_dbo_national_address) and lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,postcode_nospace
)
,nlpg_pc_summ_curr as (/*Summary Post Codes National Gazetteer - NLPG*/
    select  row_number() over (partition by postcode_nospace order by postcode_nospace desc ) as nlpg_rn_curr ,gazetteer as nlpg_gazetteer_curr /*,locality as nlpg_locality_curr ,ward as nlpg_ward_curr ,town as nlpg_town_curr*/ ,postcode as nlpg_postcode_curr ,postcode_nospace as nlpg_postcode_nospace_curr
    ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as nlpg_area_curr
    /*,count(*) as nlpg_num_records_curr*/ FROM unrestricted_address_api_dbo_national_address where unrestricted_address_api_dbo_national_address.import_date = (SELECT max(unrestricted_address_api_dbo_national_address.import_date) FROM unrestricted_address_api_dbo_national_address) and lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,postcode_nospace 
)
,nlpg_pc_summ_per as (/*Summary Post Codes National Gazetteer - NLPG*/
    select row_number() over (partition by postcode_nospace order by postcode_nospace desc ) as nlpg_rn_per ,gazetteer as nlpg_gazetteer_per/*,locality as nlpg_locality_per ,ward as nlpg_ward_per ,town as nlpg_town_per*/ ,postcode as nlpg_postcode_per ,postcode_nospace as nlpg_postcode_nospace_per
            ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as nlpg_area_per
    /*,count(*) as nlpg_num_records_per*/ FROM unrestricted_address_api_dbo_national_address where unrestricted_address_api_dbo_national_address.import_date = (SELECT max(unrestricted_address_api_dbo_national_address.import_date) FROM unrestricted_address_api_dbo_national_address) and lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,postcode_nospace 
)
, llpg_pc_summ_reg as (/*Summary Post Codes Hackney Gazetteer - LLPG*/
    select row_number() over (partition by replace(postcode_nospace,' ','') order by replace(postcode_nospace,' ','') desc ) as llpg_rn_reg ,gazetteer as llpg_gazetteer_reg /*,locality as llpg_locality_reg ,ward as llpg_ward_reg ,town as llpg_town_reg*/ ,postcode as llpg_postcode_reg ,replace(postcode_nospace,' ','') as llpg_postcode_nospace_reg
    ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as llpg_area_reg
    /*,count(*) as llpg_num_records_reg*/ FROM unrestricted_address_api_dbo_hackney_address where unrestricted_address_api_dbo_hackney_address.import_date = (SELECT max(unrestricted_address_api_dbo_hackney_address.import_date) FROM unrestricted_address_api_dbo_hackney_address) and lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,replace(postcode_nospace,' ','')
)
, llpg_pc_summ_curr as (/*Summary Post Codes Hackney Gazetteer - LLPG*/
    select row_number() over (partition by replace(postcode_nospace,' ','') order by replace(postcode_nospace,' ','') desc ) as llpg_rn_curr ,gazetteer as llpg_gazetteer_curr /*,locality as llpg_locality_curr ,ward as llpg_ward_curr ,town as llpg_town_curr*/ ,postcode as llpg_postcode_curr ,replace(postcode_nospace,' ','') as llpg_postcode_nospace_curr
    ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as llpg_area_curr
    /*,count(*) as llpg_num_records_curr*/ FROM unrestricted_address_api_dbo_hackney_address where unrestricted_address_api_dbo_hackney_address.import_date = (SELECT max(unrestricted_address_api_dbo_hackney_address.import_date) FROM unrestricted_address_api_dbo_hackney_address) and lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,replace(postcode_nospace,' ','')
)
, llpg_pc_summ_per as (/*Summary Post Codes Hackney Gazetteer - LLPG*/
    select row_number() over (partition by replace(postcode_nospace,' ','') order by replace(postcode_nospace,' ','') desc ) as llpg_rn_per ,gazetteer as llpg_gazetteer_per /*,locality as llpg_locality_per ,ward as llpg_ward_per ,town as llpg_town_per*/ ,postcode as llpg_postcode_per ,replace(postcode_nospace,' ','') as llpg_postcode_nospace_per
    ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as llpg_area_per
    /*,count(*) as llpg_num_records_per*/ FROM unrestricted_address_api_dbo_hackney_address where unrestricted_address_api_dbo_hackney_address.import_date = (SELECT max(unrestricted_address_api_dbo_hackney_address.import_date) FROM unrestricted_address_api_dbo_hackney_address) and lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,replace(postcode_nospace,' ','')
)


,permit as (/*all permit records with llpg*/
     select replace(postcode,' ','') as per_postcode_ns
     ,sr_usrn as per_sr_usrn
     ,sr_address1 as per_sr_address1
     ,sr_address2 as per_sr_address2
     ,street_description as per_street_description
     ,sr_ward_code as per_sr_ward_code
     ,sr_ward_name as per_sr_ward_name
     ,property_shell as per_property_shell
     ,blpu_class as per_blpu_class
     ,usage_primary as per_usage_primary
     ,usage_description as per_usage_description
     ,street as per_street
     ,add_type as per_add_type
     ,add_class as per_add_class
     ,zone_name as per_zone_name
     ,permit_summary as per_permit_summary
     ,permit_full_address as per_permit_full_address
     ,full_address as per_full_address
     ,permit_full_address_type as per_permit_full_address_type
     ,full_address_type as per_full_address_type
--     ,live_flag as per_live_flag
     ,case when latest_permit_status in('Approved','Renewed','Created','ORDER_APPROVED','PENDING_VRM_CHANGE','RENEW_EVID','PENDING_ADDR_CHANGE') and live_permit_flag = 1 then 1 else 0 end as per_live_flag 
     ,flag_lp_est_bb_zero as per_flag_lp_est_bb_zero
     ,flag_lp_bb_onst as per_flag_lp_bb_onst
     ,flag_lp_est as per_flag_lp_est
     ,flag_lp_bus as per_flag_lp_bus
     ,flag_lp_doc as per_flag_lp_doc
     ,flag_lp_lc as per_flag_lp_lc
     ,flag_lp_hsc as per_flag_lp_hsc
     ,flag_lp_res as per_flag_lp_res
     ,flag_lp_disp as per_flag_lp_disp
     ,flag_lp_othr as per_flag_lp_othr
     ,flag_lp_al as per_flag_lp_al
     ,flag_lp_cb as per_flag_lp_cb
     ,flag_ltn_london_fields as per_flag_ltn_london_fields
     ,flag_name_ltn_london_fields as per_flag_name_ltn_london_fields
     ,permit_reference as per_permit_reference
     ,application_date as per_application_date
     ,forename_of_applicant as per_forename_of_applicant
     ,surname_of_applicant as per_surname_of_applicant
     ,email_address_of_applicant as per_email_address_of_applicant
     ,blue_badge_number as per_blue_badge_number
     ,blue_badge_expiry as per_blue_badge_expiry
     ,start_date as per_start_date
     ,end_date as per_end_date
     ,approval_date as per_approval_date
     ,approved_by as per_approved_by
     ,approval_type as per_approval_type
     ,amount as per_amount
     ,payment_location as per_payment_location
     ,permit_type as per_permit_type
     ,business_name as per_business_name
     ,hasc_organisation_name as per_hasc_organisation_name
     ,doctors_surgery_name as per_doctors_surgery_name
     ,uprn as per_uprn
     ,address_line_1 as per_address_line_1
     ,address_line_2 as per_address_line_2
     ,address_line_3 as per_address_line_3
     ,postcode as per_postcode
     ,cpz as per_cpz
     ,cpz_name as per_cpz_name
     ,status as per_status
     ,quantity as per_quantity
     ,vrm as per_vrm
     ,live_permit_flag as per_live_permit_flag
     ,permit_fta_renewal as per_permit_fta_renewal
     ,latest_permit_status as per_latest_permit_status
     ,rn as per_rn
     ,make as per_make
     ,model as per_model
     ,fuel as per_fuel
     ,engine_capactiy as per_engine_capactiy
     ,co2_emission as per_co2_emission
     ,foreign as per_foreign
     ,lpg_conversion as per_lpg_conversion
     ,vrm_record_created as per_vrm_record_created
     ,import_year as per_import_year
     ,import_month as per_import_month
     ,import_day as per_import_day
     ,import_date as per_import_date
     FROM parking_permit_denormalised_gds_street_llpg where import_date = (SELECT max(import_date) FROM parking_permit_denormalised_gds_street_llpg) 
)
, pcn as  (
Select/*Registered extracted post codes*/
case when length(regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') ) = 0 or regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') is null or  regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like '' or  regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like ' '  then 'No Address' else regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})')  end
as reg_add_extracted_post_code
,Case when /*000*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 0 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 0 
    then 'No Address'
when (/*398*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 and upper(substr(registered_keeper_address, -6, 6)) like 'LONDON%')
    or (/*298*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 and ( substr(registered_keeper_address, -9, 9) like 'Hackney%' or  substr(registered_keeper_address, -9, 9) like 'Limited'))
    or /*198*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or (/*196*/position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 and  substr(registered_keeper_address, -9, 9) like 'Essex%')  
    or /*099*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 0 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 9 
    then 'No Post Code'
When /*196 and n16*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 and substr(registered_keeper_address, -9, 9) like ' N16 %' then /*-9 = 9*/ substr(registered_keeper_address, -9, 9)
when (/*496*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6  and  substr(registered_keeper_address, -10, 8) like 'MK43%') then substr(registered_keeper_address, -10, 8)
when /*395*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 5 and  substr(registered_keeper_address, -11, 8) like 'MK14%' then /*-11 =8*/ substr(registered_keeper_address, -11, 8)
when /*395*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 5 and substr(registered_keeper_address, -10, 7) like 'N17%' then /*-10 =7*/ substr(registered_keeper_address, -10, 7)
when (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like ',CM%' or  substr(registered_keeper_address, -9, 9) like ',IG%')) 
    or /*597*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 5 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7
    or (/*496*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6  and substr(registered_keeper_address, -10, 8) like 'MK43%')
    then /*8*/ substr(registered_keeper_address, -8, 8)
when /*598*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 5 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  or (/*597*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 5 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7  and   substr(registered_keeper_address, -9, 9) like 'NDON%') then /*4*/ substr(registered_keeper_address, -4, 4)
when (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like 'ONDON%' or  substr(registered_keeper_address, -9, 9) like 'MFORD %' or  substr(registered_keeper_address, -9, 9) like 'Essex %')) then /*3*/ substr(registered_keeper_address, -3, 3)
when /*897*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 8 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7  
    or (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like 'T,%' or  substr(registered_keeper_address, -9, 9) like 't,%' or  substr(registered_keeper_address, -9, 9) like 'n,%' or  substr(registered_keeper_address, -9, 9) like 'N,%' or substr(registered_keeper_address, -9, 9) like 'd,%' or  substr(registered_keeper_address, -9, 9) like 'm,%'))
    or /*496*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 
    or /*298*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or /*297*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    or /*196*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6
    or (/*498*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and  substr(registered_keeper_address, -9, 9) like 'HA9%')
    then /*7*/ substr(registered_keeper_address, -7, 7)
when /*798*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 7 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8   then /*2*/ substr(registered_keeper_address, -2, 2)
when (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like ',Â %' or  substr(registered_keeper_address, -9, 9) like 'ON,%' or   substr(registered_keeper_address, -9, 9) like 'on,%')) 
    or /*498*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or /*497*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    or /*398*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or /*397*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    then /*6*/ substr(registered_keeper_address, -6, 6)
when/*197*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    then /*8*/ substr(registered_keeper_address, -9, 9)
when /*396*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 
    then /*5*/ substr(registered_keeper_address, -5, 5)
when /*296*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 
    then  /*-7 =6*/ substr(registered_keeper_address, -7, 6)
when /*193*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 3 
    then /*-13 = 7*/ substr(registered_keeper_address, -13, 7)

else  substr(registered_keeper_address, -9, 9) end  as reg_add_extracted_post_code_v1

,replace(/*extracted post codes no spaces*/
case when length(regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') ) = 0 or regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})')  is null or regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})')  like '' or regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})')  like ' ' then 'No Address' else regexp_extract(registered_keeper_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') end
,' ','') as reg_add_extracted_post_code_no_space

,replace(/*extracted post codes no spaces*/
(Case
when /*000*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 0 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 0 
    then 'No Address'
when (/*398*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 and upper(substr(registered_keeper_address, -6, 6)) like 'LONDON%')
    or (/*298*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 and ( substr(registered_keeper_address, -9, 9) like 'Hackney%' or  substr(registered_keeper_address, -9, 9) like 'Limited'))
    or /*198*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or (/*196*/position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 and  substr(registered_keeper_address, -9, 9) like 'Essex%')  
    or /*099*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 0 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 9 
    then 'No Post Code'
When /*196 and n16*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 and substr(registered_keeper_address, -9, 9) like ' N16 %' then /*-9 = 9*/ substr(registered_keeper_address, -9, 9)
when (/*496*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6  and  substr(registered_keeper_address, -10, 8) like 'MK43%') then substr(registered_keeper_address, -10, 8)
when /*395*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 5 and  substr(registered_keeper_address, -11, 8) like 'MK14%' then /*-11 =8*/ substr(registered_keeper_address, -11, 8)
when /*395*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 5 and substr(registered_keeper_address, -10, 7) like 'N17%' then /*-10 =7*/ substr(registered_keeper_address, -10, 7)
when (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like ',CM%' or  substr(registered_keeper_address, -9, 9) like ',IG%')) 
    or /*597*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 5 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7
    or (/*496*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6  and substr(registered_keeper_address, -10, 8) like 'MK43%')
    then /*8*/ substr(registered_keeper_address, -8, 8)
when /*598*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 5 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  or (/*597*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 5 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7  and   substr(registered_keeper_address, -9, 9) like 'NDON%') then /*4*/ substr(registered_keeper_address, -4, 4)
when (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like 'ONDON%' or  substr(registered_keeper_address, -9, 9) like 'MFORD %' or  substr(registered_keeper_address, -9, 9) like 'Essex %')) then /*3*/ substr(registered_keeper_address, -3, 3)
when /*897*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 8 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7  
    or (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like 'T,%' or  substr(registered_keeper_address, -9, 9) like 't,%' or  substr(registered_keeper_address, -9, 9) like 'n,%' or  substr(registered_keeper_address, -9, 9) like 'N,%' or substr(registered_keeper_address, -9, 9) like 'd,%' or  substr(registered_keeper_address, -9, 9) like 'm,%'))
    or /*496*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 
    or /*298*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or /*297*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    or /*196*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6
    or (/*498*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and  substr(registered_keeper_address, -9, 9) like 'HA9%')
    then /*7*/ substr(registered_keeper_address, -7, 7)
when /*798*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 7 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8   
    then /*2*/ substr(registered_keeper_address, -2, 2)
when (/*698*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 6 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8  and (  substr(registered_keeper_address, -9, 9) like ',Â %' or  substr(registered_keeper_address, -9, 9) like 'ON,%' or   substr(registered_keeper_address, -9, 9) like 'on,%')) 
    or /*498*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or /*497*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 4 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    or /*398*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 8 
    or /*397*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    then /*6*/ substr(registered_keeper_address, -6, 6)
when/*197*/  position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 7 
    then /*8*/ substr(registered_keeper_address, -9, 9)
when /*396*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 3 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 
    then /*5*/ substr(registered_keeper_address, -5, 5)
when /*296*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 2 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 6 
    then  /*-7 =6*/ substr(registered_keeper_address, -7, 6)
when /*193*/ position(' ' in substr(registered_keeper_address, -9, 9)) = 1 and length(regexp_replace(substr(registered_keeper_address, -9, 9),'\s','')) = 3 
    then /*-13 = 7*/ substr(registered_keeper_address, -13, 7)

else  substr(registered_keeper_address, -9, 9) end )
,' ','') as reg_add_extracted_post_code_no_space_v1

/*Current*/
,case when length(regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') ) = 0 or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') is null or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like '' or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like ' ' then 'No Address' else regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') end
as curr_add_extracted_post_code

,Case/*extracted post codes*/
when /*000*/ position(' ' in substr(current_ticket_address, -9, 9)) = 0 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 0 
    then 'No Address'
when (/*398*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 and upper(substr(current_ticket_address, -6, 6)) like 'LONDON%')
    or (/*298*/ position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 and ( substr(current_ticket_address, -9, 9) like 'Hackney%' or  substr(current_ticket_address, -9, 9) like 'Limited'))
    or /*198*/ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or (/*196*/position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 and  substr(current_ticket_address, -9, 9) like 'Essex%')  
    or /*099*/ position(' ' in substr(current_ticket_address, -9, 9)) = 0 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 9 
    then 'No Post Code'
when (/*196 and DA CR IG HP2 N1*/position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 and  (substr(current_ticket_address, -9, 9) like ' HP2 %' or substr(current_ticket_address, -9, 9) like ' N1%' or substr(current_ticket_address, -9, 9) like ' DA%' or substr(current_ticket_address, -9, 9) like ' CR%' or substr(current_ticket_address, -9, 9) like ' IG%'  or substr(current_ticket_address, -9, 9) like ' E12 %' or substr(current_ticket_address, -9, 9) like ' B90 %'    ))
    or  (/*496 and SL2*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6  and  substr(current_ticket_address, -9, 9) like 'SL2 %') then substr(current_ticket_address, -9, 9)
when (/*496*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6  and  substr(current_ticket_address, -10, 8) like 'MK43%') then substr(current_ticket_address, -10, 8)
when /*395*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 5 and  substr(current_ticket_address, -11, 8) like 'MK14%' then /*-11 =8*/ substr(current_ticket_address, -11, 8)
when /*395*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 5 and substr(current_ticket_address, -10, 7) like 'N17%' then /*-10 =7*/ substr(current_ticket_address, -10, 7)
when (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like ',CM%' or  substr(current_ticket_address, -9, 9) like ',IG%')) 
    or /*597*/  position(' ' in substr(current_ticket_address, -9, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7
    or (/*496*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6  and substr(current_ticket_address, -10, 8) like 'MK43%')
    then /*8*/ substr(current_ticket_address, -8, 8)
when /*598*/  position(' ' in substr(current_ticket_address, -9, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  or (/*597*/ position(' ' in substr(current_ticket_address, -9, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7  and   substr(current_ticket_address, -9, 9) like 'NDON%') then /*4*/ substr(current_ticket_address, -4, 4)
when (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like 'ONDON%' or  substr(current_ticket_address, -9, 9) like 'MFORD %' or  substr(current_ticket_address, -9, 9) like 'Essex %')) then /*3*/ substr(current_ticket_address, -3, 3)
when /*897*/ position(' ' in substr(current_ticket_address, -9, 9)) = 8 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7  
    or (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like 'T,%' or  substr(current_ticket_address, -9, 9) like 't,%' or  substr(current_ticket_address, -9, 9) like 'n,%' or  substr(current_ticket_address, -9, 9) like 'N,%' or substr(current_ticket_address, -9, 9) like 'd,%' or  substr(current_ticket_address, -9, 9) like 'm,%'))
    or /*496*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 
    or /*298*/  position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or /*297*/  position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    or /*196*/  position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6
    or (/*498*/ position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and  substr(current_ticket_address, -9, 9) like 'HA9%')
    then /*7*/ substr(current_ticket_address, -7, 7)
when /*798*/ position(' ' in substr(current_ticket_address, -9, 9)) = 7 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8   
    then /*2*/ substr(current_ticket_address, -2, 2)
when (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like ',Â %' or  substr(current_ticket_address, -9, 9) like 'ON,%' or   substr(current_ticket_address, -9, 9) like 'on,%')) 
    or /*498*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or /*497*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    or /*398*/  position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or /*397*/  position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    then /*6*/ substr(current_ticket_address, -6, 6)
when/*197*/  position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    then /*8*/ substr(current_ticket_address, -9, 9)
when /*396*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 
    then /*5*/ substr(current_ticket_address, -5, 5)
when /*296*/ position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 
    then  /*-7 =7*/ substr(current_ticket_address, -7, 7)
when /*-99=193 -139=296 */ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 and  position(' ' in substr(current_ticket_address, -13, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -13, 9),'\s','')) = 6 then /*-11 =6*/ substr(current_ticket_address, -11, 6)
when /*-99=193 -139=196 */ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 and  position(' ' in substr(current_ticket_address, -13, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -13, 9),'\s','')) = 6 then /*-12 =7*/ substr(current_ticket_address, -12, 7)
when /*-99=193 -139=597 */ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 and  position(' ' in substr(current_ticket_address, -13, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -13, 9),'\s','')) = 7 then /*-13 =8*/ substr(current_ticket_address, -13, 8)
when /*193*/ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 
    then /*-13 = 7*/ substr(current_ticket_address, -13, 7)

else  substr(current_ticket_address, -9, 9) end as curr_add_extracted_post_code_v1

,replace(/*extracted post codes no spaces*/
case when length(regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') ) = 0 or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') is null or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like '' or regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') like ' ' then 'No Address' else regexp_extract(current_ticket_address, '([A-Za-z][A-Ha-hJ-Yj-y]?[0-9][A-Za-z0-9]? ?[0-9][A-Za-z]{2}|[Gg][Ii][Rr] ?0[Aa]{2})') end
,' ','') as curr_add_extracted_post_code_no_space

,replace(/*extracted post codes no spaces*/
(Case
when /*000*/ position(' ' in substr(current_ticket_address, -9, 9)) = 0 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 0 
    then 'No Address'
when (/*398*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 and upper(substr(current_ticket_address, -6, 6)) like 'LONDON%')
    or (/*298*/ position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 and ( substr(current_ticket_address, -9, 9) like 'Hackney%' or  substr(current_ticket_address, -9, 9) like 'Limited'))
    or /*198*/ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or (/*196*/position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 and  substr(current_ticket_address, -9, 9) like 'Essex%')  
    or /*099*/ position(' ' in substr(current_ticket_address, -9, 9)) = 0 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 9 
    then 'No Post Code'
when (/*196 and DA CR IG HP2 N1*/position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 and  (substr(current_ticket_address, -9, 9) like ' HP2 %' or substr(current_ticket_address, -9, 9) like ' N1%' or substr(current_ticket_address, -9, 9) like ' DA%' or substr(current_ticket_address, -9, 9) like ' CR%' or substr(current_ticket_address, -9, 9) like ' IG%'  or substr(current_ticket_address, -9, 9) like ' E12 %' or substr(current_ticket_address, -9, 9) like ' B90 %'    ))
    or  (/*496 and SL2*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6  and  substr(current_ticket_address, -9, 9) like 'SL2 %') then substr(current_ticket_address, -9, 9)
when (/*496*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6  and  substr(current_ticket_address, -10, 8) like 'MK43%') then substr(current_ticket_address, -10, 8)
when /*395*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 5 and  substr(current_ticket_address, -11, 8) like 'MK14%' then /*-11 =8*/ substr(current_ticket_address, -11, 8)
when /*395*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 5 and substr(current_ticket_address, -10, 7) like 'N17%' then /*-10 =7*/ substr(current_ticket_address, -10, 7)
when (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like ',CM%' or  substr(current_ticket_address, -9, 9) like ',IG%')) 
    or /*597*/  position(' ' in substr(current_ticket_address, -9, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7
    or (/*496*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6  and substr(current_ticket_address, -10, 8) like 'MK43%')
    then /*8*/ substr(current_ticket_address, -8, 8)
when /*598*/  position(' ' in substr(current_ticket_address, -9, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  or (/*597*/ position(' ' in substr(current_ticket_address, -9, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7  and   substr(current_ticket_address, -9, 9) like 'NDON%') then /*4*/ substr(current_ticket_address, -4, 4)
when (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like 'ONDON%' or  substr(current_ticket_address, -9, 9) like 'MFORD %' or  substr(current_ticket_address, -9, 9) like 'Essex %')) then /*3*/ substr(current_ticket_address, -3, 3)
when /*897*/ position(' ' in substr(current_ticket_address, -9, 9)) = 8 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7  
    or (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like 'T,%' or  substr(current_ticket_address, -9, 9) like 't,%' or  substr(current_ticket_address, -9, 9) like 'n,%' or  substr(current_ticket_address, -9, 9) like 'N,%' or substr(current_ticket_address, -9, 9) like 'd,%' or  substr(current_ticket_address, -9, 9) like 'm,%'))
    or /*496*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 
    or /*298*/  position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or /*297*/  position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    or /*196*/  position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6
    or (/*498*/ position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and  substr(current_ticket_address, -9, 9) like 'HA9%')
    then /*7*/ substr(current_ticket_address, -7, 7)
when /*798*/ position(' ' in substr(current_ticket_address, -9, 9)) = 7 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8
    then /*2*/ substr(current_ticket_address, -2, 2)
when (/*698*/ position(' ' in substr(current_ticket_address, -9, 9)) = 6 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8  and (  substr(current_ticket_address, -9, 9) like ',Â %' or  substr(current_ticket_address, -9, 9) like 'ON,%' or substr(current_ticket_address, -9, 9) like 'on,%'))
    or /*498*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or /*497*/  position(' ' in substr(current_ticket_address, -9, 9)) = 4 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    or /*398*/  position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 8 
    or /*397*/  position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    then /*6*/ substr(current_ticket_address, -6, 6)
when/*197*/  position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 7 
    then /*8*/ substr(current_ticket_address, -9, 9)
when /*396*/ position(' ' in substr(current_ticket_address, -9, 9)) = 3 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 then /*5*/ substr(current_ticket_address, -5, 5)
when /*296*/ position(' ' in substr(current_ticket_address, -9, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 6 then  /*-7 =7*/ substr(current_ticket_address, -7, 7)
when /*-99=193 -139=296 */ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 and  position(' ' in substr(current_ticket_address, -13, 9)) = 2 and length(regexp_replace(substr(current_ticket_address, -13, 9),'\s','')) = 6 then /*-11 =6*/ substr(current_ticket_address, -11, 6)
when /*-99=193 -139=196 */ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 and  position(' ' in substr(current_ticket_address, -13, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -13, 9),'\s','')) = 6 then /*-12 =7*/ substr(current_ticket_address, -12, 7)
when /*-99=193 -139=597 */ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 and  position(' ' in substr(current_ticket_address, -13, 9)) = 5 and length(regexp_replace(substr(current_ticket_address, -13, 9),'\s','')) = 7 then /*-13 =8*/ substr(current_ticket_address, -13, 8)
when /*193*/ position(' ' in substr(current_ticket_address, -9, 9)) = 1 and length(regexp_replace(substr(current_ticket_address, -9, 9),'\s','')) = 3 then /*-13 = 7*/ substr(current_ticket_address, -13, 7)


else  substr(current_ticket_address, -9, 9) end )
,' ','') as curr_add_extracted_post_code_no_space_v1
,* FROM pcnfoidetails_pcn_foi_full where import_date = (SELECT max(import_date) FROM pcnfoidetails_pcn_foi_full)
)

select
/*PCN with no address linked to Permit with address*/
case when
(/*no address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' and curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=1
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
then 1 end as pcn_no_add_link_permit

/*PCN with no address linked to Permit with address not cancelled or closed*/
,case when
(/*no address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' and curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=1
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and pcn_canx_date is null
and pcn_casecloseddate is null
then 1 end as open_pcn_no_add_link_permit

/*pcn registered address not same as linked permit address*/
,case when
(/*not match reg add permit add*/case when reg_add_extracted_post_code_no_space = per_postcode_ns then 0 else 1 end)=1
and (/*has reg address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
then 1 end as reg_add_link_permit_diff 

/*pcn registered address not same as linked permit address not cancelled or close*/
,case when
(/*not match reg add permit add*/case when reg_add_extracted_post_code_no_space = per_postcode_ns then 0 else 1 end)=1
and (/*has reg address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
and pcn_canx_date is null
and pcn_casecloseddate is null
then 1 end as open_reg_add_link_permit_diff 

/*PCN with non llpg registered address linked to Permit with address*/
,case when
(/*reg add not in llpg*/case when llpg_postcode_nospace_reg is not null or llpg_postcode_nospace_reg not like '' or llpg_postcode_nospace_reg not like ' ' then 1 else 0 end)=0
and (/*has reg address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
then 1 end as reg_add_not_llpg_link_permit

/*PCN with non llpg registered address linked to Permit with address not cancelled or close*/
,case when
(/*reg add not in llpg*/case when llpg_postcode_nospace_reg is not null or llpg_postcode_nospace_reg not like '' or llpg_postcode_nospace_reg not like ' ' then 1 else 0 end)=0
and (/*has reg address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
and pcn_canx_date is null
and pcn_casecloseddate is null
then 1 end as open_reg_add_not_llpg_link_permit

/*PCN with non llpg current address linked to Permit with address*/
,case when
(/*curr add not in llpg*/case when llpg_postcode_nospace_curr is not null or llpg_postcode_nospace_curr not like '' or llpg_postcode_nospace_curr not like ' ' then 1 else 0 end)=0
and (/*has curr address*/case when curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
then 1  end as curr_add_not_llpg_link_permit

/*PCN with non llpg current address linked to Permit with address not cancelled or close*/
,case when
(/*curr add not in llpg*/case when llpg_postcode_nospace_curr is not null or llpg_postcode_nospace_curr not like '' or llpg_postcode_nospace_curr not like ' ' then 1 else 0 end)=0
and (/*has curr address*/case when curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
and pcn_canx_date is null
and pcn_casecloseddate is null
then 1  end as open_curr_add_not_llpg_link_permit

/*In LLPG or not*/
,case when llpg_postcode_nospace_reg is not null or llpg_postcode_nospace_reg not like '' or llpg_postcode_nospace_reg not like ' ' then 1 else 0 end as post_code_in_llpg_reg
,case when llpg_postcode_nospace_curr is not null or llpg_postcode_nospace_curr not like '' or llpg_postcode_nospace_curr not like ' ' then 1 else 0 end as post_code_in_llpg_curr
,case when llpg_postcode_nospace_per is not null or llpg_postcode_nospace_per not like '' or llpg_postcode_nospace_per not like ' ' then 1 else 0 end as post_code_in_llpg_per
/*pcn postcode different from permit postcode*/
,case when (per_postcode_ns is not null or per_postcode_ns not like '' or per_postcode_ns not like ' ') and reg_add_extracted_post_code_no_space is not null and reg_add_extracted_post_code_no_space = per_postcode_ns then 0 else 1 end as diff_reg_pc_per_pc
,case when (per_postcode_ns is not null or per_postcode_ns not like '' or per_postcode_ns not like ' ')  and curr_add_extracted_post_code_no_space is not null and curr_add_extracted_post_code_no_space = per_postcode_ns then 0 else 1 end as diff_curr_pc_per_pc
,case when 
    ((per_postcode_ns is not null or per_postcode_ns not like '' or per_postcode_ns not like ' ') and reg_add_extracted_post_code_no_space is not null and reg_add_extracted_post_code_no_space = per_postcode_ns) 
    or ((per_postcode_ns is not null or per_postcode_ns not like '' or per_postcode_ns not like ' ')  and curr_add_extracted_post_code_no_space is not null and curr_add_extracted_post_code_no_space = per_postcode_ns)
    then 0 else 1 end as diff_pcn_pc_per_pc
/*pcn registered different to current postcode*/
,case when reg_add_extracted_post_code_no_space is not null and (reg_add_extracted_post_code_no_space = curr_add_extracted_post_code_no_space) then 0 else 1 end as diff_reg_pc_curr_pc

/*PCN no address*/
,case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end as reg_add_no_address
,case when curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end as curr_add_no_address
,case when reg_add_extracted_post_code_no_space like 'NoAddress' and curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end as pcn_both_no_address
/*PCN no postcode*/
,case when reg_add_extracted_post_code_no_space like 'NoPostCode' then 1 else 0 end as reg_add_no_postcode
,case when curr_add_extracted_post_code_no_space like 'NoPostCode' then 1 else 0 end as curr_add_no_postcode
,case when reg_add_extracted_post_code_no_space like 'NoPostCode' and curr_add_extracted_post_code_no_space like 'NoPostCode' then 1 else 0 end as pcn_both_no_postcode

/*pcn postcodes different to permit llpg postcode*/
,case when llpg_postcode_nospace_per is not null and reg_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and (reg_add_extracted_post_code_no_space = llpg_postcode_nospace_per) then 0 else 1 end as diff_reg_pc_llpg_per_pc
,case when llpg_postcode_nospace_per is not null and curr_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and  (curr_add_extracted_post_code_no_space = llpg_postcode_nospace_per) then 0 else 1 end as diff_curr_pc_llpg_per_pc
,case when 
    (llpg_postcode_nospace_per is not null and reg_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and (reg_add_extracted_post_code_no_space = llpg_postcode_nospace_per)) 
    or (llpg_postcode_nospace_per is not null and curr_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and  (curr_add_extracted_post_code_no_space = llpg_postcode_nospace_per)) 
    then 0 else 1 end as diff_pcn_pc_llpg_per_pc
/*Permit linked to pcn record*/
,case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end as has_permit
,case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 0 else 1 end as no_permit
/*Permit has no address in data*/
,case when (per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/) and per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end as permit_no_address
, replace(registered_keeper_address, ',', '') as reg_add_no_comma
, replace(current_ticket_address, ',', '') as curr_add_no_comma
,* -- pcn.*, permit.*
FROM pcn
left join permit on permit.per_vrm = pcn.vrm and (case when pcn.pcnissuedate >= permit.per_start_date and pcn.pcnissuedate <= permit.per_end_date then 1 else 0 end)=1
left join nlpg_pc_summ_reg on upper(replace(nlpg_pc_summ_reg.nlpg_postcode_nospace_reg,' ','')) = upper(pcn.reg_add_extracted_post_code_no_space) and nlpg_rn_reg = 1
left join nlpg_pc_summ_curr on upper(replace(nlpg_pc_summ_curr.nlpg_postcode_nospace_curr,' ','')) = upper(pcn.curr_add_extracted_post_code_no_space) and nlpg_rn_curr = 1
left join nlpg_pc_summ_per on upper(replace(nlpg_pc_summ_per.nlpg_postcode_nospace_per,' ','')) = upper(replace(permit.per_postcode,' ','')) and nlpg_rn_per = 1

left join llpg_pc_summ_reg on upper(replace(llpg_pc_summ_reg.llpg_postcode_nospace_reg,' ','')) = upper(pcn.reg_add_extracted_post_code_no_space) and llpg_rn_reg  = 1
left join llpg_pc_summ_curr on upper(replace(llpg_pc_summ_curr.llpg_postcode_nospace_curr,' ','')) = upper(pcn.curr_add_extracted_post_code_no_space) and llpg_rn_curr  = 1
left join llpg_pc_summ_per on upper(replace(llpg_pc_summ_per.llpg_postcode_nospace_per,' ','')) = upper(replace(permit.per_postcode,' ','')) and llpg_rn_per  = 1

where pcn.pcnissuedate > current_date - interval '13' month  --Last 13 months from todays date
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "unrestricted_address_api_dbo_national_address": S3bucketunrestricted_address_api_dbo_national_address_node1,
        "unrestricted_address_api_dbo_hackney_address": AmazonS3unrestricted_address_api_dbo_hackney_address_node1650475065696,
        "parking_permit_denormalised_gds_street_llpg": AmazonS3parking_permit_denormalised_gds_street_llpg_node1650475071787,
        "pcnfoidetails_pcn_foi_full": AmazonS3pcnfoidetails_pcn_foi_full_node1650477300290,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/manual/parking_match_pcn_permit_vrm_with_address_match_llpg_nlpg_postcodes/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="parking-refined-zone",
    catalogTableName="parking_match_pcn_permit_vrm_with_address_match_llpg_nlpg_postcodes",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
