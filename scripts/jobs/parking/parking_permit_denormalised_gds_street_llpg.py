"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_permit_denormalised_gds_street_llpg"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
-- Updated 2025-01-29 "unrestricted-raw-zone"."geolive_llpg_llpg_address" replaces "dataplatform-prod-raw-zone-unrestricted-address-api"."unrestricted_address_api_dbo_hackney_address"
with street as (select
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
FROM "dataplatform-prod-liberator-raw-zone".liberator_permit_llpg
where (ADDRESS1 like 'Street Record' or ADDRESS1 like 'STREET RECORD') and liberator_permit_llpg.import_date = (SELECT MAX(liberator_permit_llpg.import_date) FROM "dataplatform-prod-liberator-raw-zone".liberator_permit_llpg)
)
, llpg as (
  SELECT
	-- conversion of new column names and data-types to support the original query...
	uprn, 		 -- bigint -- Confirmed: was previously converted from double to bigint to prevent subsequent varchar casts being broken.
	usrn,							-- int
	street_description,				-- string
	isparent AS property_shell, 	-- boolean
	blpu_class, 					-- string
	usage_primary, 					-- string
	usage_description,				-- string
	planning_use_class,				-- string
	CAST(longitude AS DOUBLE) AS longitude, -- converts string to double
	CAST(latitude AS DOUBLE) AS latitude, 	-- converts string to double
	lpi_logical_status_code,		-- int BS7666 code
	lpi_logical_status,				--string logical description as per previous API version
	import_date						-- string
  FROM "unrestricted-raw-zone"."geolive_llpg_llpg_address"
  -- replaces "dataplatform-prod-raw-zone-unrestricted-address-api"."unrestricted_address_api_dbo_hackney_address"
  where import_date = (SELECT max(import_date) FROM "unrestricted-raw-zone"."geolive_llpg_llpg_address")
  	and lpi_logical_status_code = 1 -- like 'Approved Preferred'
  )
SELECT
	street.usrn as sr_usrn,
	SR_ADDRESS1, SR_ADDRESS2,
	llpg.street_description,
	SR_WARD_CODE,
	SR_ward_name,
	llpg.property_shell,
	llpg.blpu_class,
	llpg.usage_primary,
	llpg.usage_description,
	concat(cast(street.usrn as varchar),' - ', llpg.street_description) as street,
	concat(cast(llpg.uprn as varchar),' - ',llpg.usage_description) as add_type,
	concat(llpg.blpu_class,' - ',llpg.planning_use_class ) as add_class,

case when cpz !='' and cpz_name != '' then concat(cpz,' - ', cpz_name)
when cpz !='' and cpz_name = '' then concat(cpz,'-')
when cpz ='' and cpz_name != '' then concat(cpz_name,'-')
else 'NONE'
end as zone_name,
case

when address_line_2 ='' and business_name ='' and hasc_organisation_name ='' and  doctors_surgery_name ='' then concat(permit_reference,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when business_name !='' and hasc_organisation_name !='' and address_line_2 ='' then concat(permit_reference,' - ',business_name,' - ',hasc_organisation_name,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when business_name !='' and doctors_surgery_name !='' and address_line_2 ='' then concat(permit_reference,' - ',business_name,' - ',doctors_surgery_name,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when business_name !='' and address_line_2 ='' then concat(permit_reference,' - ',business_name,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when hasc_organisation_name !='' and address_line_2 ='' then concat(permit_reference,' - ',hasc_organisation_name,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when doctors_surgery_name !='' and address_line_2 ='' then concat(permit_reference,' - ',doctors_surgery_name,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)

when address_line_3 =''and business_name ='' and hasc_organisation_name ='' and  doctors_surgery_name ='' then concat(permit_reference,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when business_name !='' and hasc_organisation_name !='' and address_line_3 ='' then concat(permit_reference,' - ',business_name,' - ',hasc_organisation_name,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when business_name !='' and doctors_surgery_name !='' and address_line_3 ='' then concat(permit_reference,' - ',business_name,' - ',doctors_surgery_name,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when business_name !='' and address_line_3 ='' then concat(permit_reference,' - ',business_name,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when hasc_organisation_name !='' and address_line_3 ='' then concat(permit_reference,' - ',hasc_organisation_name,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when doctors_surgery_name !='' and address_line_3 ='' then concat(permit_reference,' - ',doctors_surgery_name,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)


when business_name !='' then concat(permit_reference,' - ',business_name,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when hasc_organisation_name !='' then concat(permit_reference,' - ',hasc_organisation_name,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
when doctors_surgery_name !='' then concat(permit_reference,' - ',doctors_surgery_name,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)

else concat(permit_reference,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode,' - ',email_address_of_applicant)
end as permit_summary


,case
when address_line_2 ='' then concat(permit_reference,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode)
when address_line_3 ='' then concat(permit_reference,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode)
else concat(permit_reference,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode)
end as permit_full_address
,case
when address_line_2 ='' then concat(address_line_1,', ',parking_permit_denormalised_data.postcode)
when address_line_3 ='' then concat(address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode)
else concat(address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode)
end as full_address

,case
when address_line_2 ='' then concat(permit_reference,' - ',usage_primary,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode)
when address_line_3 ='' then concat(permit_reference,' - ',usage_primary,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode)
else concat(permit_reference,' - ',usage_primary,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode)
end as permit_full_address_type

,case
when address_line_2 ='' then concat(usage_primary,' - ',address_line_1,', ',parking_permit_denormalised_data.postcode)
when address_line_3 ='' then concat(usage_primary,' - ',address_line_1,', ',address_line_2,', ',parking_permit_denormalised_data.postcode)
else concat(usage_primary,' - ',address_line_1,', ',address_line_2,', ',address_line_3,', ',parking_permit_denormalised_data.postcode)
end as full_address_type

,case when latest_permit_status in('Approved','Renewed','Created','ORDER_APPROVED','PENDING_VRM_CHANGE','RENEW_EVID','PENDING_ADDR_CHANGE') and live_permit_flag = 1 then 1 else 0 end as live_flag

,Case when live_permit_flag = 1 and blue_badge_number !='' and permit_type like 'Estate Resident' and (amount like '0.00' or amount like '0.000'  or amount like '') then 1 else 0 end as flag_lp_est_bb_zero
,Case when live_permit_flag = 1 and blue_badge_number !='' and permit_type != 'Estate Resident' then 1 else 0 end as flag_lp_bb_onst

,Case when live_permit_flag = 1 and permit_type like 'Estate Resident' then 1 else 0 end as flag_lp_est
,Case when live_permit_flag = 1 and permit_type like 'Business' then 1 else 0 end as flag_lp_bus
,Case when live_permit_flag = 1 and permit_type like 'Doctor' then 1 else 0 end as flag_lp_doc
,Case when live_permit_flag = 1 and permit_type like 'Leisure centre permit' then 1 else 0 end as flag_lp_lc
,Case when live_permit_flag = 1 and permit_type like 'Health and Social Care' then 1 else 0 end as flag_lp_hsc
,Case when live_permit_flag = 1 and permit_type like 'Residents' then 1 else 0 end as flag_lp_res
,Case when live_permit_flag = 1 and permit_type like 'Dispensation' then 1 else 0 end as flag_lp_disp
,Case when live_permit_flag = 1 and permit_type not in ('Estate Resident','All Zone','Companion Badge','Dispensation','Residents','Health and Social Care','Leisure centre permit','Doctor','Business') then 1 else 0 end as flag_lp_othr
,Case when live_permit_flag = 1 and permit_type like 'All Zone' then 1 else 0 end as flag_lp_al
,Case when live_permit_flag = 1 and permit_type like 'Companion Badge' then 1 else 0 end as flag_lp_cb

/* fields in ltn table -- ltn_london_fields.uprn, ltn_london_fields.usrn, ltn_london_fields.street_name*/
, Case when ltn_london_fields.uprn !='' then 1 else 0 end as flag_ltn_london_fields
, Case when ltn_london_fields.uprn !='' then 'LTN London Fields' else 'NOT LTN London Fields' end as flag_name_ltn_london_fields


, parking_permit_denormalised_data.*, llpg.planning_use_class, llpg.longitude, llpg.latitude  FROM  "dataplatform-prod-liberator-refined-zone".parking_permit_denormalised_data

left join llpg on cast(llpg.uprn as varchar) = cast(parking_permit_denormalised_data.uprn as varchar) /*and
cast(concat(parking_permit_denormalised_data.import_year,parking_permit_denormalised_data.import_month,parking_permit_denormalised_data.import_day) as varchar
) = llpg.import_date*/

left join street on cast(street.usrn as varchar) = cast(llpg.usrn as varchar)

left join "parking-raw-zone".ltn_london_fields on  ltn_london_fields.uprn = parking_permit_denormalised_data.uprn


where parking_permit_denormalised_data.import_date = (SELECT max(parking_permit_denormalised_data.import_date) FROM  "dataplatform-prod-liberator-refined-zone".parking_permit_denormalised_data)
;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
