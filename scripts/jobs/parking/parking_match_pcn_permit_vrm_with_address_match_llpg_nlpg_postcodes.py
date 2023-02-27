import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.helpers import create_pushdown_predicate_for_max_date_partition_value


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
    table_name="parking_permit_denormalised_gds_street_llpg",
    transformation_ctx="AmazonS3parking_permit_denormalised_gds_street_llpg_node1650475071787",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-"+environment+"-liberator-refined-zone", "parking_permit_denormalised_gds_street_llpg", "import_date")
)

# Script generated for node S3 bucket - unrestricted_address_api_dbo_national_address
S3bucketunrestricted_address_api_dbo_national_address_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-raw-zone-unrestricted-address-api",
    table_name="unrestricted_address_api_dbo_national_address",
    transformation_ctx="S3bucketunrestricted_address_api_dbo_national_address_node1",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-"+environment+"-raw-zone-unrestricted-address-api", "unrestricted_address_api_dbo_national_address", "import_date")
)

# Script generated for node Amazon S3 - pcnfoidetails_pcn_foi_full
AmazonS3pcnfoidetails_pcn_foi_full_node1650477300290 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-refined-zone",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3pcnfoidetails_pcn_foi_full_node1650477300290",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-"+environment+"-liberator-refined-zone", "pcnfoidetails_pcn_foi_full", "import_date")
)

# Script generated for node Amazon S3 - unrestricted_address_api_dbo_hackney_address
AmazonS3unrestricted_address_api_dbo_hackney_address_node1650475065696 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-raw-zone-unrestricted-address-api",
    table_name="unrestricted_address_api_dbo_hackney_address",
    transformation_ctx="AmazonS3unrestricted_address_api_dbo_hackney_address_node1650475065696",
    push_down_predicate=create_pushdown_predicate_for_max_date_partition_value("dataplatform-"+environment+"-raw-zone-unrestricted-address-api", "unrestricted_address_api_dbo_hackney_address", "import_date")
)

# Script generated for node ApplyMapping
SqlQuery13 = """
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
24/02/2023 - optimised query to alias NLPG and LLPG in joins and add additional fields 
*/

With nlpg_pc_summ as (/*Summary Post Codes National Gazetteer - NLPG*/
    select row_number() over (partition by postcode_nospace order by postcode_nospace desc ) as nlpg_rn ,gazetteer as nlpg_gazetteer /*,locality as nlpg_locality_reg ,ward as nlpg_ward_reg ,town as nlpg_town_reg*/ ,postcode as nlpg_postcode ,postcode_nospace as nlpg_postcode_nospace
        ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as nlpg_area 
    /*,count(*) as nlpg_num_records_reg*/ FROM unrestricted_address_api_dbo_national_address where lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,postcode_nospace
)
, llpg_pc_summ as (/*Summary Post Codes Hackney Gazetteer - LLPG*/
    select row_number() over (partition by replace(postcode_nospace,' ','') order by replace(postcode_nospace,' ','') desc ) as llpg_rn ,gazetteer as llpg_gazetteer /*,locality as llpg_locality_reg ,ward as llpg_ward_reg ,town as llpg_town_reg*/ ,postcode as llpg_postcode ,replace(postcode_nospace,' ','') as llpg_postcode_nospace
    ,case
        when upper(town) like 'LONDON%' and upper(locality) ='HACKNEY' and ward !='' then concat(ward, ' - ',locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality !='' then concat(locality, ' - ',town)
        when upper(town) like 'LONDON%' and locality ='' and ward !='' then concat(ward, ' - ',town) 
        else town end as llpg_area
    /*,count(*) as llpg_num_records_reg*/ FROM unrestricted_address_api_dbo_hackney_address where lpi_logical_status like 'Approved Preferred'
    group by gazetteer, locality ,ward ,town ,postcode ,replace(postcode_nospace,' ','')
)



,permit as (/*all permit records with llpg*/
     select replace(postcode,' ','') as per_postcode_ns
     ,sr_usrn as per_sr_usrn
     ,replace(sr_address1, ',', '') as per_sr_address1
     ,replace(sr_address2, ',', '') as per_sr_address2
     ,replace(street_description, ',', '') as per_street_description
     ,sr_ward_code as per_sr_ward_code
     ,sr_ward_name as per_sr_ward_name
     ,property_shell as per_property_shell
     ,blpu_class as per_blpu_class
     ,replace(usage_primary, ',', '') as per_usage_primary
     ,replace(usage_description, ',', '') as per_usage_description
     ,replace(street, ',', '') as per_street
     ,replace(add_type, ',', '') as per_add_type
     ,add_class as per_add_class
     ,zone_name as per_zone_name
     ,replace(case 

when address_line_2 ='' and business_name ='' and hasc_organisation_name ='' and  doctors_surgery_name ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',address_line_1,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when business_name !='' and hasc_organisation_name !='' and address_line_2 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',business_name,' - ',hasc_organisation_name,' - ',address_line_1,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when business_name !='' and doctors_surgery_name !='' and address_line_2 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',business_name,' - ',doctors_surgery_name,' - ',address_line_1,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when business_name !='' and address_line_2 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',business_name,' - ',address_line_1,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when hasc_organisation_name !='' and address_line_2 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',hasc_organisation_name,' - ',address_line_1,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when doctors_surgery_name !='' and address_line_2 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',doctors_surgery_name,' - ',address_line_1,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)

when address_line_3 =''and business_name ='' and hasc_organisation_name ='' and  doctors_surgery_name ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',address_line_1,' ',address_line_2,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when business_name !='' and hasc_organisation_name !='' and address_line_3 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',business_name,' - ',hasc_organisation_name,' - ',address_line_1,', ',address_line_2,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when business_name !='' and doctors_surgery_name !='' and address_line_3 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',business_name,' - ',doctors_surgery_name,' - ',address_line_1,', ',address_line_2,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when business_name !='' and address_line_3 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',business_name,' - ',address_line_1,' ',address_line_2,', ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when hasc_organisation_name !='' and address_line_3 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant ,' - ',hasc_organisation_name,' - ',address_line_1,' ',address_line_2,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when doctors_surgery_name !='' and address_line_3 ='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',doctors_surgery_name,' - ',address_line_1,' ',address_line_2,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)


when business_name !='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',business_name,' - ',address_line_1,' ',address_line_2,' ',address_line_3,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)
when hasc_organisation_name !='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',hasc_organisation_name,' - ',address_line_1,' ',address_line_2,' ',address_line_3,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant) 
when doctors_surgery_name !='' then concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',doctors_surgery_name,' - ',address_line_1,' ',address_line_2,' ',address_line_3,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant)

else concat(permit_reference,' - ',forename_of_applicant,' ',surname_of_applicant,' - ',address_line_1,' ',address_line_2,' ',address_line_3,' ',parking_permit_denormalised_gds_street_llpg.postcode,' - ',email_address_of_applicant) 
end, ',', '') as per_permit_contact_summary
     ,replace(permit_summary, ',', '') as per_permit_summary
     ,replace(permit_full_address, ',', '') as per_permit_full_address
     ,replace(full_address, ',', '') as per_full_address
     ,replace(permit_full_address_type, ',', '') as per_permit_full_address_type
     ,replace(full_address_type, ',', '') as per_full_address_type
     ,live_flag as per_live_flag
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
     ,replace(hasc_organisation_name, ',', '') as per_hasc_organisation_name
     ,replace(doctors_surgery_name, ',', '') as per_doctors_surgery_name
     ,uprn as per_uprn
     ,replace(address_line_1, ',', '') as per_address_line_1
     ,replace(address_line_2, ',', '') as per_address_line_2
     ,replace(address_line_3, ',', '') as per_address_line_3
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
     FROM parking_permit_denormalised_gds_street_llpg 
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
,* FROM pcnfoidetails_pcn_foi_full
)

/*.....................................................................................................................*/
select distinct
Case
when cast(pcnissuedate as varchar(10)) like '2028-03-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2028-02-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2028-01-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-12-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-11-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-10-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-09-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-08-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-07-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-06-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-05-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-04-%'  THEN '2027'
when cast(pcnissuedate as varchar(10)) like '2027-03-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2027-02-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2027-01-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-12-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-11-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-10-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-09-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-08-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-07-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-06-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-05-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-04-%'  THEN '2026'
when cast(pcnissuedate as varchar(10)) like '2026-03-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2026-02-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2026-01-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-12-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-11-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-10-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-09-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-08-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-07-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-06-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-05-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-04-%'  THEN '2025'
when cast(pcnissuedate as varchar(10)) like '2025-03-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2025-02-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2025-01-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-12-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-11-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-10-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-09-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-08-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-07-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-06-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-05-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-04-%'  THEN '2024'
when cast(pcnissuedate as varchar(10)) like '2024-03-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2024-02-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2024-01-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-12-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-11-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-10-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-09-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-08-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-07-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-06-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-05-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-04-%'  THEN '2023'
when cast(pcnissuedate as varchar(10)) like '2023-03-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2023-02-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2023-01-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-12-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-11-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-10-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-09-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-08-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-07-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-06-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-05-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-04-%'  THEN '2022'
when cast(pcnissuedate as varchar(10)) like '2022-03-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2022-02-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2022-01-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-12-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-11-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-10-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-09-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-08-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-07-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-06-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-05-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-04-%'  THEN '2021'
when cast(pcnissuedate as varchar(10)) like '2021-03-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2021-02-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2021-01-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-12-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-11-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-10-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-09-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-08-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-07-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-06-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-05-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-04-%'  THEN '2020'
when cast(pcnissuedate as varchar(10)) like '2020-03-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2020-02-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2020-01-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-12-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-11-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-10-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-09-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-08-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-07-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-06-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-05-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-04-%'  THEN '2019'
when cast(pcnissuedate as varchar(10)) like '2019-03-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2019-02-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2019-01-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-12-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-11-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-10-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-09-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-08-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-07-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-06-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-05-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-04-%'  THEN '2018'
when cast(pcnissuedate as varchar(10)) like '2018-03-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2018-02-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2018-01-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-12-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-11-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-10-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-09-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-08-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-07-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-06-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-05-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-04-%'  THEN '2017'
when cast(pcnissuedate as varchar(10)) like '2017-03-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2017-02-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2017-01-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-12-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-11-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-10-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-09-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-08-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-07-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-06-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-05-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-04-%'  THEN '2016'
when cast(pcnissuedate as varchar(10)) like '2016-03-%'  THEN '2015'
when cast(pcnissuedate as varchar(10)) like '2016-02-%'  THEN '2015'
else '1900'
end as fy,

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
(/*reg add not in llpg*/case when llpg_reg.llpg_postcode_nospace is not null or llpg_reg.llpg_postcode_nospace not like '' or llpg_reg.llpg_postcode_nospace not like ' ' then 1 else 0 end)=0
and (/*has reg address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
then 1 end as reg_add_not_llpg_link_permit

/*PCN with non llpg registered address linked to Permit with address not cancelled or close*/
,case when
(/*reg add not in llpg*/case when llpg_reg.llpg_postcode_nospace is not null or llpg_reg.llpg_postcode_nospace not like '' or llpg_reg.llpg_postcode_nospace not like ' ' then 1 else 0 end)=0
and (/*has reg address*/case when reg_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
and pcn_canx_date is null
and pcn_casecloseddate is null
then 1 end as open_reg_add_not_llpg_link_permit

/*PCN with non llpg current address linked to Permit with address*/
,case when
(/*curr add not in llpg*/case when llpg_curr.llpg_postcode_nospace is not null or llpg_curr.llpg_postcode_nospace not like '' or llpg_curr.llpg_postcode_nospace not like ' ' then 1 else 0 end)=0
and (/*has curr address*/case when curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
then 1  end as curr_add_not_llpg_link_permit

/*PCN with non llpg current address linked to Permit with address not cancelled or close*/
,case when
(/*curr add not in llpg*/case when llpg_curr.llpg_postcode_nospace is not null or llpg_curr.llpg_postcode_nospace not like '' or llpg_curr.llpg_postcode_nospace not like ' ' then 1 else 0 end)=0
and (/*has curr address*/case when curr_add_extracted_post_code_no_space like 'NoAddress' then 1 else 0 end)=0
and (/*Has permit*/case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end)=1
and (/*no permit postcode*/case when per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end) =0
and pcn_canx_date is null
and pcn_casecloseddate is null
then 1  end as open_curr_add_not_llpg_link_permit

/*In LLPG or not*/
,case when llpg_reg.llpg_postcode_nospace is not null or llpg_reg.llpg_postcode_nospace not like '' or llpg_reg.llpg_postcode_nospace not like ' ' then 1 else 0 end as post_code_in_llpg_reg
,case when llpg_curr.llpg_postcode_nospace is not null or llpg_curr.llpg_postcode_nospace not like '' or llpg_curr.llpg_postcode_nospace not like ' ' then 1 else 0 end as post_code_in_llpg_curr
,case when llpg_per.llpg_postcode_nospace is not null or llpg_per.llpg_postcode_nospace not like '' or llpg_per.llpg_postcode_nospace not like ' ' then 1 else 0 end as post_code_in_llpg_per
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
,case when llpg_per.llpg_postcode_nospace is not null and reg_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and (reg_add_extracted_post_code_no_space = llpg_per.llpg_postcode_nospace) then 0 else 1 end as diff_reg_pc_llpg_per_pc
,case when llpg_per.llpg_postcode_nospace is not null and curr_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and  (curr_add_extracted_post_code_no_space = llpg_per.llpg_postcode_nospace) then 0 else 1 end as diff_curr_pc_llpg_per_pc
,case when 
    (llpg_per.llpg_postcode_nospace is not null and reg_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and (reg_add_extracted_post_code_no_space = llpg_per.llpg_postcode_nospace)) 
    or (llpg_per.llpg_postcode_nospace is not null and curr_add_extracted_post_code_no_space is not null and per_permit_type not like 'All Zone' and  (curr_add_extracted_post_code_no_space = llpg_per.llpg_postcode_nospace)) 
    then 0 else 1 end as diff_pcn_pc_llpg_per_pc
/*Permit linked to pcn record*/
,case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 1 else 0 end as has_permit
,case when per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/ then 0 else 1 end as no_permit
/*Permit has no address in data*/
,case when (per_permit_reference is not null or per_permit_reference like '' or per_permit_reference like ' '  /*some permits no address*/) and per_postcode_ns is null or per_postcode_ns like '' or per_postcode_ns like ' ' then 1 else 0 end as permit_no_address
, replace(registered_keeper_address, ',', '') as reg_add_no_comma
, replace(current_ticket_address, ',', '') as curr_add_no_comma
,replace(whereonlocation, ',', '') as whereonlocation_no_comma

,case when replace(registered_keeper_address, ',', '') != 'Redacted. Cancellation due to vehicle mismatch SA99' and ( replace(registered_keeper_address, ',', '') in ('ONTO HOLDINGS LIMITED 05012- UNIT 3 HERMES COURT HERMES CLOSE WARWICK CV34 6NJ', 
'CONTRACT VEHICLESLTD 049293 PO BOX 875 LEEDS LS1 9RX', 
'VOLKSWAGEN GROUP LEASING C/O 012683 C/O VWFS (UK) LTD BRUNSWICK COURT YEOMANS DRIVE BLAKELANDS MILTON KEYNES MK14 5LR', 
'OGILVIE FLEET LTD 04197- C/O OGILVIE FLEET LTD OGILVIE HOUSE 200 GLASGOW RD STIRLING FK7 8ES', 
'NATALIA MOSCHOU 05074- C/O LEX AUTOLEASE LTD HEATHSIDE PARK HEATHSIDE PARK ROAD STOCKPORT SK3 0RB', 
'VOLKSWAGEN GROUP LEASING C/O 049566 C/O EVENTECH LTD UNIT A BULLS BRIDGE CENTRE NORTH HYDE HAYES UB3 4QR', 
'LEX AUTOLEASE LIMITED 05074- C/O LEX AUTOLEASE LIMITED HEATHSIDE PARK HEATHSIDE PARK ROAD STOCKPORT SK3 0RB', 
'MSL VEHICLE SOLUTIONS LTD 049797 1 LAKESIDE CHEADLE SK8 3GW', 
'LAND ROVER CONTRACT HIRE 05074- C/O LEX AUTOLEASE LIMITED HEATHSIDE PARK HEATHSIDE PARK ROAD STOCKPORT SK3 0RB', 
'PCO RENTALS LTD 050374 7TH FLOOR HYDE HOUSE EDGWARE ROAD LONDON NW9 6LH', 
'ALPHABET (GB) LTD 037886 PO BOX 1295 BOONGATE PETERBOROUGH PETERBOROUGH PE1 9QW', 
'LEX AUTOLEASE LIMITED 05074- HEATHSIDE PARK HEATHSIDE PARK ROAD STOCKPORT SK3 0RB', 
'REFLEX VEHICLE HIRE LTD 045901 22 BELTON ROAD WEST LOUGHBOROUGH LE11 5TR', 
'PSD VEHICLE RENTAL 555 PRESCOTT ROAD ST HELENS WA10 3BZ', 
'LEASEPLAN UK LIMITED 021490 C/O LEASEPLAN UK LTD 165 BATH ROAD SLOUGH SL1 4AA', 
'AMI VEHICLE LEASING LTD 04555- 16-20 MILLERS YARD PARLIAMENT SQUARE HERTFORD SG14 1EZ', 
'PENDRAGON VEHICLE MANAGEMENT LTD 032177 PENDRAGON HOUSE SIR FRANK WHITTLE ROAD DERBY DE21 4AZ', 
'LEASEPLAN UK LTD 021490 C/O LEASEPLAN UK LTD 165 BATH ROAD SLOUGH SL1 4AA', 
'CAR CASTLE LTD 145A PLASHET ROAD LONDON E13 0RA', 
'FREE2MOVE LEASE 048847 C/O FREE2MOVE LEASE PO BOX 17263 SOLIHULL B93 3JB', 
'VOLKSWAGEN FINANCIAL SERVICES(UK)LTD 012683 C/O VWFS (UK) LTD BRUNSWICK COURT YEOMANS DRIVE BLAKELANDS MILTON KEYNES MK14 5LR', 
'VITUS VEHICLE HIRE LTD FLAT 9 SEBASTIAN HOUSE HOXTON STREET LONDON N1 6QH', 
'ZENITH VEHICLE CONTRACTS LTD 037783 C/O ZENITH VEH CONTRACTS LTD NUMBER ONE GT EXHIBITION WAY KIRKSTALL FO LEEDS LS5 3BF', 
'ZENITH VEHICLE CONTRACTS LIMITED 037783 NUMBER ONE GREAT EXHIBITION WAY KIRKSTALL FORGE LEEDS LS5 3BF', 
'MARSHALL LEASING LTD C/O FOXTONS GROUP PLC 97 VICTORIA ROAD LONDON NW10 6DJ', 
'LEASEPLAN UK LTD 021490 165 BATH ROAD SLOUGH SL1 4AA', 
'KJ PCO RENTALS LTD UNIT A4 BOUNDS GREEN INDUSTRIAL ESTATE RINGWAY LONDON N11 2UD', 
'CONTRACT VEHICLES LTD 049293 PO BOX 875 LEEDS LS1 9RX', 
'REFLEX VEHICLE HIRE LIMITED 22 BELTON ROAD WEST LOUGHBOROUGH LE11 5TR', 
'LEX AUTOLEASE LTD 05074- HEATHSIDE PARK HEATHSIDE PARK ROAD STOCKPORT SK3 0RB', 
'SPLEND LTD 050532 C/O SPLEND LTD 393 EDGWARE ROAD CRICKLEWOOD LONDON NW2 6LN', 
'AVT LTD ALL VEHICLE TYPES 83 HAWTHORNE CLOSE LONDON N1 4AW', 
'SAFE & SOUND VEHICLE SYSTEMS 41 KENT CLOSE PUDSEY LS28 9EY', 
'L & F PLANT HIRE LTD 15 WHARF ROAD ENFIELD EN3 4TA', 
'ENTERPRISE RENT A CAR UK LTD 046103 C/O ENTERPRISE RENTACAR UK LTD PO BOX 77 ALDERSHOT GU11 9DY', 
'SPRINTSHIFT COMMERCIAL VEHICLE HIRE 17 OUTRAM ROAD BROADWAY INDUSTRIAL ESTATE DUKINFIELD SK16 4XE', 
'WESTGATE VEHICLE HIRE LTD SUITE 40 UNIMIX HOUSE ABBEY ROAD LONDON NW10 7TR', 
'SPARK VEHICLE REPAIR 118 WARHAM ROAD LONDON N4 1AU', 
'TOOMEY LEASING GROUP LTD 045688 SERVICE HOUSE WEST MAYNE BASILDON SS15 6RW', 
'MG VEHICLE HIRE LTD FLAT 2 79 PARK ROAD LONDON E10 7BZ', 
'LEASYS UK LTD 045135 C/O HUDSON KAPEL LTD PO BOX 1413 COOMBELANDS PARK BEDFORD MK44 1ZY', 
'OGILVIE FLEET LTD 04197- OGILVIE HOUSE 200 GLASGOW RD STIRLING FK7 8ES', 
'MOBILITY VEHICLE HIRE 238 BIRMINGHAM ROAD GREAT BARR BIRMINGHAM B43 7AH', 
'SUNBLET RENTALS LTD 049293 C/O CONTRACT VEHICLES LTD PO BOX 875 LEEDS LS1 9RX', 
'MAXXIS CAR LTD 162 A CHIGWELL ROAD WOODFORD LONDON E18 1HA', 
'ARVAL MID-TERM RENTAL 02644- C/O ARVAL UK LTD WINDMILL HILL SWINDON SN5 6PE', 
'RAPID VEHICLE MANAGEMENT 160 LONDON ROAD SEVENOAKS TN13 1BT', 
'GLYN HOPKIN VEHICLE RENTAL LTD 279-289 LONDON ROAD - - ROMFORD RM7 9NP', 
'ISMAAEL CAR RENTAL LTD 36 CAVELL ROAD LONDON N17 7BJ', 
'CONTRACT VEHICLES LTD 049293 C/O CONTRACT VEHICLES LTD PO BOX 875 LEEDS LS1 9RX', 
'ENTERPRISE RENTACAR UK LTD 046103 C/O ENTERPRISE RENTACAR UK LTD PO BOX 77 ALDERSHOT GU11 9DY', 
'PENDRAGON VEHICLE MANAGEMENT LIMITED 032177 PENDRAGON HOUSE SIR FRANK WHITTLE ROAD DERBY DE21 4AZ', 
'CHS VEHICLES LTD 126 GELDERD CLOSE LEEDS LS12 6DS', 
'AK VEHICLE MANAGEMENT LTD 41 BLOCK A THE VISTA CENTRE SALISBURY ROAD HOUNSLOW TW4 6JQ', 
'IMPERIAL VEHICLE HIRE LTD 050465 GROUND FLOOR SUITE B PEACOCK HOUSE NORTHBRIDGE ROAD BERKHAMSTED HP4 1EH', 
'MITSUBISHI HC CAPITAL UK PLC 048781 HAKUBA HOUSE WHITE HORSE BUSINESS PARK TROWBRIDGE BA14 0FL', 
'GLYN HOPKIN VEHICLE RENTAL LTD 279-289 LONDON ROAD ROMFORD RM7 9NP', 
'EXCLUSIVE VEHICLE CONTRACTS LT D 5 AMPTHILL BUSINESS PARK STATION ROAD AMPTHILL BEDFORD MK45 2QW', 
'AMT VEHICLE RENTAL LTD ATHLON MOBILITY SVCS UK LTD C/O AMT VEHICLE RENTAL LTD 174 ARMLEY ROAD LEEDS LS12 2QH', 
'SMART VEHICLE RENTAL LTD 366 LORDSHIP LANE LONDON N17 7QX', 
'ZENITH VEHICLE CONTRACTS LTD 037783 NUMBER ONE GREAT EXHIBITION WA LEEDS LS5 3BF', 
'SMART VEHICLE RENTAL LIMITED 366 LORDSHIP LANE LONDON N17 7QX', 
'VAUXHALL FINANCE PLC C/O ABRIDGE VEHICLE MANAGEMENT LTD 9 BLENHEIM COURT BROOK WAY LEATHERHEAD KT22 7NA', 
'RAPID VEHICLE MANAGEMENT LTD 160 LONDON ROAD SEVENOAKS TN13 1BT', 
'ZENITH VEHICLE CONTRACTS 037783 C/O ZENITH VEH CONTRACTS LTD NUMBER ONE GT EXHIBITION WAY KIRKSTALL FO LEEDS LS5 3BF', 
'PRIME ECO CARS LTD 9 MALDEN ROAD LONDON NW5 3HS', 
'CLOSE BROTHERS VEHICLE HIRE LOWS LANE STANTON BY DALE ILKESTON DE7 4QU', 
'MARSHALL LEASING LTD C/O FOXTONS LTD 97 VICTORIA ROAD LONDON NW10 6DJ', 
'TRUCKPOINT VEHICLE HIRE LTD 69 BOROUGH ROAD LONDON SE1 1DN', 
'MERIDIAN VEHICLE SOLUTIONS LTD 048288 UNIT 21 MCDONALD BUSINESS PARK MCDONALD WAY HEMEL HEMPSTEAD HP2 7EB', 
'ANNIE MCDONAGH 044441 VEHICLE KEEPER 6 CENTENARY PARK OMAGH BT78 5HH', 
'FIRST VEHICLE MANAGMENTLTD WOODVILLE SOUTH STREET BOUGHTON-UNDER-BLEAN FAVERSHAM ME13 9NS', 
'BUSSEY VEHICLE LEASING FIRST FLOOR 95 WHIFFLER ROAD NORWICH NR3 2AW', 
'ABRIDGE VEHICLE MANAGEMENT LTD 048641 C/O ABRIDGE VEH MANAGEMENT LTD 9 BLENHEIM COURT BROOK WAY LEATHERHEAD KT22 7NA', 
'ACROBAT VEHICLE RENTAL LTD UNION LANE KINGSCLERE NEWBURY RG20 4ST', 
'NORTHGATE VEHICLE HIRE LTD 046541 C/O GOODE DURRANT ADMIN LTD PO BOX 287 DARLINGTON DL1 9LW', 
'ARI FLEET LEASING UK LTD 042560 C/O ARI FLEET UK LTD METHUEN PARK CHIPPENHAM SN14 0GX', 
'GAP VEHICLE HIRE LTD 050271 C/O GAP VEHICLE HIRE LTD 13 SYMINGTON DRIVE CLYDEBANK BUSINESS PARK CLYDEBANK G81 2LD', 
'ZENITH VEHICLE CONTRACTS LTD 037783 C/O ZENITH VEH CONTRACTS LTD NUMBER ONE GT EXHIBITION WAY KIRKSTALL FORGE LEEDS LS5 3BF', 
'GAP VEHICLE HIRE LTD 050271 13 SYMINGTON DRIVE CLYDEBANK BUSINESS PARK CLYDEBANK G81 2LD', 
'VOLKSWAGEN GROUP LEASING 012683 C/O VWFS (UK) LTD BRUNSWICK COURT YEOMANS DRIVE BLAKELANDS MILTON KEYNES MK14 5LR', 
'RIVUS FLEET SOLUTIONS LTD 033029 2620 KINGS COURT THE CRESCENT BIRMINGHAM BUSINESS PARK BIRMINGHAM B37 7YE', 
'ALD AUTOMOTIVE LTD 036705 C/O ALD AUTOMOTIVE LIMITED OAKWOOD DRIVE EMERSONS GREEN BRISTOL BS16 7LB', 
'ALD AUTOMOTIVE LTD 036705 OAKWOOD DRIVE EMERSONS GREEN BRISTOL BS16 7LB', 
'ENTERPRISE RENTACAR UK LTD 046103 PO BOX 77 ALDERSHOT GU11 9DY', 
'LOOKERS LEASING LIMITED 04233- C/O LOOKERS LEASING LIMITED LOOKERS HOUSE CARDALE PARK BECKWITH HEAD ROA HARROGATE HG3 1RY', 
'THE AUTOMOBILE ASSOCIATION DEVELOPMENTS LTD 033029 C/O RIVUS FLEET SOLUTIONS LTD 2620 KINGS COURT THE CRESCENT BIRMINGHAM BUSINESS PARK BIRMINGHAM B37 7YE', 
'MARSHALL LEASING LTD 032931 C/O MARSHALL LEASING LTD BRIDGE HOUSE ORCHARD LANE HUNTINGDON PE29 3QT', 
'EVENTECH LTD UNIT A BULLS BRIDGE CENTRE NORTH HYDE GARDENS HAYES UB3 4QR', 
'VWFS (UK) LTD 012683 BRUNSWICK COURT YEOMANS DRIVE BLAKELANDS MILTON KEYNES MK14 5LR', 
'ALD AUTOMOTIVE LIMITED 036705 OAKWOOD DRIVE EMERSONS GREEN BRISTOL BS16 7LB', 
'ALD AUTOMOTIVE LTD 036705 OAKWOOD PARK LODGE CAUSEWAY BRISTOL BS16 3JA', 
'MARHSALL LEASING LTD C/O FOXTONS GROUP PLC 97 VICTORIA ROAD LONDON NW10 6DJ', 
'RA CAR RENTAL LTD 75 LEYTON PARK ROAD LONDON E10 5RL', 
'SHAHI CARS LIMITED SUITE 114 116 BALLARDS LANE LONDON N3 2DN', 
'ARROW CAR HIRE UK LONDON LTD 57 HALLSVILE ROAD LONDON E16 1EE'
) ) then 1 end as rental_lease_reg_add 
,case 
when replace(registered_keeper_address, ',', '') != 'Redacted. Cancellation due to vehicle mismatch SA99'
and (upper(replace(registered_keeper_address, ',', '')) like '%RENTAL%' 
or upper(replace(registered_keeper_address, ',', ''))  like '%LEASING%' 
or upper(replace(registered_keeper_address, ',', ''))  like '%LEASE%' 
or upper(replace(registered_keeper_address, ',', ''))  like '%HIRE%' 
or  upper(replace(registered_keeper_address, ',', ''))  like '%RENTACAR%'  
or  upper(replace(registered_keeper_address, ',', ''))  like '%VEHICLE%') then 1  end as flag_vehicle_rental_hire_lease_reg_add
,case 
when replace(registered_keeper_address, ',', '') != 'Redacted. Cancellation due to vehicle mismatch SA99'
and (upper(replace(registered_keeper_address, ',', '')) like '%LIMITED%' 
or upper(replace(registered_keeper_address, ',', ''))  like '%LTD%' 
or upper(replace(registered_keeper_address, ',', ''))  like '%PO BOX%' 
or upper(replace(registered_keeper_address, ',', ''))  like '%C/O%' 
) then 1  end as flag_vehicle_company_reg_add
,pcn.*, permit.*--, nlpg_reg.*, nlpg_curr.*,nlpg_per.*, llpg_reg.*, llpg_curr.*,llpg_per.*
--*,
--output from NLPG --nlpg_rn, nlpg_gazetteer, nlpg_postcode, nlpg_postcode_nospace, nlpg_area
--output from llpg --llpg_rn, llpg_gazetteer, llpg_postcode, llpg_postcode_nospace, llpg_area

, nlpg_reg.nlpg_gazetteer as nlpg_gazetteer_reg ,nlpg_reg.nlpg_postcode as nlpg_postcode_reg ,nlpg_reg.nlpg_postcode_nospace as nlpg_postcode_nospace_reg ,nlpg_reg.nlpg_area as nlpg_area_reg 
,nlpg_curr.nlpg_gazetteer as nlpg_gazetteer_curr ,nlpg_curr.nlpg_postcode as nlpg_postcode_curr ,nlpg_curr.nlpg_postcode_nospace as nlpg_postcode_nospace_curr ,nlpg_curr.nlpg_area as nlpg_area_curr
,nlpg_per.nlpg_gazetteer as nlpg_gazetteer_per ,nlpg_per.nlpg_postcode as nlpg_postcode_per ,nlpg_per.nlpg_postcode_nospace as nlpg_postcode_nospace_per ,nlpg_per.nlpg_area as nlpg_area_per
,llpg_reg.llpg_gazetteer as llpg_gazetteer_reg ,llpg_reg.llpg_postcode as llpg_postcode_reg ,llpg_reg.llpg_postcode_nospace as llpg_postcode_nospace_reg ,llpg_reg.llpg_area as llpg_area_reg
,llpg_curr.llpg_gazetteer as llpg_gazetteer_curr ,llpg_curr.llpg_postcode as llpg_postcode_curr ,llpg_curr.llpg_postcode_nospace as llpg_postcode_nospace_curr ,llpg_curr.llpg_area as llpg_area_curr
,llpg_per.llpg_gazetteer as llpg_gazetteer_per ,llpg_per.llpg_postcode as llpg_postcode_per ,llpg_per.llpg_postcode_nospace as llpg_postcode_nospace_per ,llpg_per.llpg_area as llpg_area_per

FROM pcn
left join permit on permit.per_vrm = pcn.vrm and (case when pcn.pcnissuedate >= permit.per_start_date and pcn.pcnissuedate <= permit.per_end_date then 1 else 0 end)=1
left join nlpg_pc_summ nlpg_reg on upper(replace(nlpg_reg.nlpg_postcode_nospace,' ','')) = upper(pcn.reg_add_extracted_post_code_no_space) and nlpg_reg.nlpg_rn = 1
left join nlpg_pc_summ nlpg_curr on upper(replace(nlpg_curr.nlpg_postcode_nospace,' ','')) = upper(pcn.curr_add_extracted_post_code_no_space) and nlpg_curr.nlpg_rn = 1
left join nlpg_pc_summ nlpg_per on upper(replace(nlpg_per.nlpg_postcode_nospace,' ','')) = upper(replace(permit.per_postcode,' ','')) and nlpg_per.nlpg_rn = 1

left join llpg_pc_summ llpg_reg on upper(replace(llpg_reg.llpg_postcode_nospace,' ','')) = upper(pcn.reg_add_extracted_post_code_no_space) and llpg_reg.llpg_rn  = 1
left join llpg_pc_summ llpg_curr on upper(replace(llpg_curr.llpg_postcode_nospace,' ','')) = upper(pcn.curr_add_extracted_post_code_no_space) and llpg_curr.llpg_rn  = 1
left join llpg_pc_summ llpg_per on upper(replace(llpg_per.llpg_postcode_nospace,' ','')) = upper(replace(permit.per_postcode,' ','')) and llpg_per.llpg_rn  = 1

where pcn.pcnissuedate > current_date - interval '13' month  --Last 13 months from todays date
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery13,
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

