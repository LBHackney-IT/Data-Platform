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
-->> "dataplatform-prod-liberator-refined-zone"."parking_permit_denormalised_gds_street_llpg"
-- < "dataplatform-prod-liberator-refined-zone"."parking_permit_denormalised_data"
-- < "dataplatform-prod-liberator-raw-zone"."liberator_permit_llpg"
-- < "unrestricted-raw-zone"."geolive_llpg_llpg_address"
-- 		(replaces "dataplatform-prod-raw-zone-unrestricted-address-api"."unrestricted_address_api_dbo_hackney_address")
-- < "parking-raw-zone"."ltn_london_fields"

-- 2025-01-29: "geolive_llpg_llpg_address" replaced "unrestricted_address_api_dbo_hackney_address")
-- 2025-02-12	Reformatted SQL, replaced wildcards and ordered columns as per existing tables in S3

WITH
street AS (
	SELECT
		UPRN AS SR_UPRN,
		ADDRESS1 AS SR_ADDRESS1,
		ADDRESS2 AS SR_ADDRESS2,
		ADDRESS3 AS SR_ADDRESS3,
		ADDRESS4 AS SR_ADDRESS4,
		ADDRESS5 AS SR_ADDRESS5,
		POST_CODE AS SR_POST_CODE,
		BPLU_CLASS AS SR_BPLU_CLASS,
		X AS SR_X,
		Y AS SR_Y,
		LATITUDE AS SR_LATITUDE,
		LONGITUDE AS SR_LONGITUDE,
		IN_CONGESTION_CHARGE_ZONE AS SR_IN_CONGESTION_CHARGE_ZONE,
		CPZ_CODE AS SR_CPZ_CODE,
		CPZ_NAME AS SR_CPZ_NAME,
		LAST_UPDATED_STAMP AS SR_LAST_UPDATED_STAMP,
		LAST_UPDATED_TX_STAMP AS SR_LAST_UPDATED_TX_STAMP,
		CREATED_STAMP AS SR_CREATED_STAMP,
		CREATED_TX_STAMP AS SR_CREATED_TX_STAMP,
		HOUSE_NAME AS SR_HOUSE_NAME,
		POST_CODE_PACKED AS SR_POST_CODE_PACKED,
		STREET_START_X AS SR_STREET_START_X,
		STREET_START_Y AS SR_STREET_START_Y,
		STREET_END_X AS SR_STREET_END_X,
		STREET_END_Y AS SR_STREET_END_Y,
		WARD_CODE AS SR_WARD_CODE,
		IF(WARD_CODE = 'E05009367', 'BROWNSWOOD WARD',    
		IF(WARD_CODE = 'E05009368', 'CAZENOVE WARD',    
		IF(WARD_CODE = 'E05009369', 'CLISSOLD WARD',    
		IF(WARD_CODE = 'E05009370', 'DALSTON WARD',    
		IF(WARD_CODE = 'E05009371', 'DE BEAUVOIR WARD',    
		IF(WARD_CODE = 'E05009372', 'HACKNEY CENTRAL WARD',    
		IF(WARD_CODE = 'E05009373', 'HACKNEY DOWNS WARD',    
		IF(WARD_CODE = 'E05009374', 'HACKNEY WICK WARD',    
		IF(WARD_CODE = 'E05009375', 'HAGGERSTON WARD',    
		IF(WARD_CODE = 'E05009376', 'HOMERTON WARD',    
		IF(WARD_CODE = 'E05009377', 'HOXTON EAST AND SHOREDITCH WARD',    
		IF(WARD_CODE = 'E05009378', 'HOXTON WEST WARD',    
		IF(WARD_CODE = 'E05009379', 'KINGS PARK WARD',    
		IF(WARD_CODE = 'E05009380', 'LEA BRIDGE WARD',    
		IF(WARD_CODE = 'E05009381', 'LONDON FIELDS WARD',    
		IF(WARD_CODE = 'E05009382', 'SHACKLEWELL WARD',    
		IF(WARD_CODE = 'E05009383', 'SPRINGFIELD WARD',    
		IF(WARD_CODE = 'E05009384', 'STAMFORD HILL WEST',    
		IF(WARD_CODE = 'E05009385', 'STOKE NEWINGTON WARD',    
		IF(WARD_CODE = 'E05009386', 'VICTORIA WARD',    
		IF(WARD_CODE = 'E05009387', 'WOODBERRY DOWN WARD',
				WARD_CODE))))))))))))))))))))
			) AS SR_ward_name, 	 
		PARISH_CODE AS SR_PARISH_CODE,
		PARENT_UPRN AS SR_PARENT_UPRN,
		PAO_START AS SR_PAO_START,
		PAO_START_SUFFIX AS SR_PAO_START_SUFFIX,
		PAO_END AS SR_PAO_END,
		PAO_END_SUFFIX AS SR_PAO_END_SUFFIX,
		PAO_TEXT AS SR_PAO_TEXT,
		SAO_START AS SR_SAO_START,
		SAO_START_SUFFIX AS SR_SAO_START_SUFFIX,
		SAO_END AS SR_SAO_END,
		SAO_END_SUFFIX AS SR_SAO_END_SUFFIX,
		SAO_TEXT AS SR_SAO_TEXT,
		DERIVED_BLPU AS SR_DERIVED_BLPU,
		USRN,
		import_year,
		import_month,
		import_day,
		import_date
	FROM
		"dataplatform-prod-liberator-raw-zone"."liberator_permit_llpg"
	WHERE import_date = (
			SELECT MAX(import_date)
			FROM "dataplatform-prod-liberator-raw-zone"."liberator_permit_llpg"
		)
		AND (
			ADDRESS1 LIKE 'Street Record'
			OR ADDRESS1 LIKE 'STREET RECORD'
		)
),

llpg AS (
	SELECT
		-- conversion of new column names and data-types to support the original query... 
		uprn, -- bigint -- Confirmed: was previously converted from double to bigint to prevent subsequent varchar casts being broken.
		usrn, -- int
		street_description, -- string
		isparent AS property_shell, -- boolean
		blpu_class, -- string
		usage_primary, -- string
		usage_description, -- string
		planning_use_class, -- string
		CAST(longitude AS DOUBLE) AS longitude, -- converts string to double
		CAST(latitude AS DOUBLE) AS latitude, -- converts string to double
		lpi_logical_status_code, -- int BS7666 code
		lpi_logical_status, --string logical description as per previous API version
		import_date -- string
	FROM
		"unrestricted-raw-zone"."geolive_llpg_llpg_address"
		-- replaces "dataplatform-prod-raw-zone-unrestricted-address-api"."unrestricted_address_api_dbo_hackney_address" 
	WHERE
		import_date = (
			SELECT
				MAX(import_date)
			FROM
				"unrestricted-raw-zone"."geolive_llpg_llpg_address"
		)
		AND lpi_logical_status_code = 1 -- like 'Approved Preferred'
)

SELECT
    street.usrn AS sr_usrn,
    SR_ADDRESS1,
    SR_ADDRESS2,
    llpg.street_description,
    SR_WARD_CODE,
    SR_ward_name,
    llpg.property_shell,
    llpg.blpu_class,
    llpg.usage_primary,
    llpg.usage_description,
    concat (CAST(street.usrn AS VARCHAR), ' - ', llpg.street_description) AS street,
    concat (CAST(llpg.uprn AS VARCHAR), ' - ', llpg.usage_description) AS add_type,
    concat (llpg.blpu_class, ' - ', llpg.planning_use_class) AS add_class,
    CASE WHEN cpz != ''
		AND cpz_name != '' THEN concat (cpz, ' - ', cpz_name)
	WHEN cpz != ''
		AND cpz_name = '' THEN concat (cpz, '-')
	WHEN cpz = ''
		AND cpz_name != '' THEN concat (cpz_name, '-')
	ELSE 'NONE'
    END AS zone_name,
    CASE WHEN address_line_2 = ''
		AND business_name = ''
		AND hasc_organisation_name = ''
		AND doctors_surgery_name = '' THEN concat (
			permit_reference,
			' - ',
			address_line_1,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != ''
		AND hasc_organisation_name != ''
		AND address_line_2 = '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			hasc_organisation_name,
			' - ',
			address_line_1,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != ''
		AND doctors_surgery_name != ''
		AND address_line_2 = '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			doctors_surgery_name,
			' - ',
			address_line_1,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != ''
		AND address_line_2 = '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			address_line_1,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN hasc_organisation_name != ''
		AND address_line_2 = '' THEN concat (
			permit_reference,
			' - ',
			hasc_organisation_name,
			' - ',
			address_line_1,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN doctors_surgery_name != ''
		AND address_line_2 = '' THEN concat (
			permit_reference,
			' - ',
			doctors_surgery_name,
			' - ',
			address_line_1,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN address_line_3 = ''
		AND business_name = ''
		AND hasc_organisation_name = ''
		AND doctors_surgery_name = '' THEN concat (
			permit_reference,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != ''
		AND hasc_organisation_name != ''
		AND address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			hasc_organisation_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != ''
		AND doctors_surgery_name != ''
		AND address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			doctors_surgery_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != ''
		AND address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN hasc_organisation_name != ''
		AND address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			hasc_organisation_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN doctors_surgery_name != ''
		AND address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			doctors_surgery_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN business_name != '' THEN concat (
			permit_reference,
			' - ',
			business_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN hasc_organisation_name != '' THEN concat (
			permit_reference,
			' - ',
			hasc_organisation_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	WHEN doctors_surgery_name != '' THEN concat (
			permit_reference,
			' - ',
			doctors_surgery_name,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
	ELSE concat (
			permit_reference,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode,
			' - ',
			email_address_of_applicant
		)
    END AS permit_summary,
    CASE WHEN address_line_2 = '' THEN concat (
			permit_reference,
			' - ',
			address_line_1,
			', ',
			p.postcode
		)
	WHEN address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode
		)
	ELSE concat (
			permit_reference,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode
		)
    END AS permit_full_address,
    CASE WHEN address_line_2 = '' THEN concat (address_line_1, ', ', p.postcode)
	WHEN address_line_3 = '' THEN concat (
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode
		)
	ELSE concat (
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode
		)
    END AS full_address,
    CASE WHEN address_line_2 = '' THEN concat (
            permit_reference,
            ' - ',
            usage_primary,
            ' - ',
            address_line_1,
            ', ',
            p.postcode
        )
	WHEN address_line_3 = '' THEN concat (
			permit_reference,
			' - ',
			usage_primary,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			p.postcode
		)
	ELSE concat (
			permit_reference,
			' - ',
			usage_primary,
			' - ',
			address_line_1,
			', ',
			address_line_2,
			', ',
			address_line_3,
			', ',
			p.postcode
		)
    END AS permit_full_address_type,
    CASE WHEN address_line_2 = '' THEN concat (
            usage_primary,
            ' - ',
            address_line_1,
            ', ',
            p.postcode
        )
	WHEN address_line_3 = '' THEN concat (
            usage_primary,
            ' - ',
            address_line_1,
            ', ',
            address_line_2,
            ', ',
            p.postcode
        )
	ELSE concat (
            usage_primary,
            ' - ',
            address_line_1,
            ', ',
            address_line_2,
            ', ',
            address_line_3,
            ', ',
            p.postcode
        )
    END AS full_address_type,
    CASE WHEN latest_permit_status IN (
            'Approved',
            'Renewed',
            'Created',
            'ORDER_APPROVED',
            'PENDING_VRM_CHANGE',
            'RENEW_EVID',
            'PENDING_ADDR_CHANGE'
        )
        AND live_permit_flag = 1 THEN 1
	ELSE 0
    END AS live_flag,
    CASE WHEN live_permit_flag = 1
        AND blue_badge_number != ''
        AND permit_type LIKE 'Estate Resident'
        AND (
            amount LIKE '0.00'
            OR amount LIKE '0.000'
            OR amount LIKE ''
        ) THEN 1
	ELSE 0
    END AS flag_lp_est_bb_zero,
    CASE WHEN live_permit_flag = 1
        AND blue_badge_number != ''
        AND permit_type != 'Estate Resident' THEN 1
	ELSE 0
    END AS flag_lp_bb_onst,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Estate Resident' THEN 1
	ELSE 0
    END AS flag_lp_est,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Business' THEN 1
	ELSE 0
    END AS flag_lp_bus,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Doctor' THEN 1
	ELSE 0
    END AS flag_lp_doc,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Leisure centre permit' THEN 1
	ELSE 0
    END AS flag_lp_lc,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Health and Social Care' THEN 1
	ELSE 0
    END AS flag_lp_hsc,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Residents' THEN 1
	ELSE 0
    END AS flag_lp_res,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Dispensation' THEN 1
	ELSE 0
    END AS flag_lp_disp,
    CASE WHEN live_permit_flag = 1
        AND permit_type NOT IN (
            'Estate Resident',
            'All Zone',
            'Companion Badge',
            'Dispensation',
            'Residents',
            'Health and Social Care',
            'Leisure centre permit',
            'Doctor',
            'Business'
        ) THEN 1
	ELSE 0
    END AS flag_lp_othr,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'All Zone' THEN 1
	ELSE 0
    END AS flag_lp_al,
    CASE WHEN live_permit_flag = 1
        AND permit_type LIKE 'Companion Badge' THEN 1
	ELSE 0
    END AS flag_lp_cb,

    /* fields in ltn table -- ltn.uprn, ltn.usrn, ltn.street_name*/
    CASE WHEN ltn.uprn != '' THEN 1
	ELSE 0
    END AS flag_ltn_london_fields,
    CASE WHEN ltn.uprn != '' THEN 'LTN London Fields'
	ELSE 'NOT LTN London Fields'
    END AS flag_name_ltn_london_fields,

	/* parking_permit_denormalised_data.* */
	p.permit_reference,
	p.application_date,
	p.forename_of_applicant,
	p.surname_of_applicant,
	p.email_address_of_applicant,
	p.primary_phone,
	p.secondary_phone,
	p.date_of_birth_of_applicant,
	p.blue_badge_number,
	p.blue_badge_expiry,
	p.start_date,
	p.end_date,
	p.approval_date,
	p.approved_by,
	p.approval_type,
	p.amount,
	p.payment_date,
	p.payment_method,
	p.payment_location,
	p.payment_by,
	p.payment_received,
	p.directorate_to_be_charged,
	p.authorising_officer,
	p.cost_code,
	p.subjective_code,
	p.permit_type,
	p.ordered_by,
	p.business_name,
	p.hasc_organisation_name,
	p.doctors_surgery_name,
	p.number_of_bays,
	p.number_of_days,
	p.number_of_dispensation_vehicles,
	p.dispensation_reason,
	p.uprn,
	p.address_line_1,
	p.address_line_2,
	p.address_line_3,
	p.postcode,
	p.cpz,
	p.cpz_name,
	p.status,
	p.quantity,
	p.vrm,
	p.associated_to_order,
	p.live_permit_flag,
	p.permit_fta_renewal,
	p.latest_permit_status,
	p.rn,
	p.make,
	p.model,
	p.fuel,
	p.engine_capactiy,
	p.co2_emission,
	p.foreign,
	p.lpg_conversion,
	p.vrm_record_created,
	p.fin_year_flag,
	p.fin_year,
	p.usrn,
	p.importdatetime,

	/* LLPG enrichment */
    llpg.planning_use_class,
    llpg.longitude,
    llpg.latitude,

	/* Partition columns from source table go last */
	p.import_year,
	p.import_month,
	p.import_day,
	p.import_date

FROM (
		SELECT * 
		FROM "dataplatform-prod-liberator-refined-zone"."parking_permit_denormalised_data"
		WHERE import_date = (
				SELECT MAX(import_date)
				FROM "dataplatform-prod-liberator-refined-zone"."parking_permit_denormalised_data"
			)
	) p
LEFT JOIN llpg
	ON CAST(llpg.uprn AS VARCHAR) = CAST(p.uprn AS VARCHAR)
    /*and 
    cast(concat(p.import_year,p.import_month,p.import_day) as varchar
    ) = llpg.import_date*/
LEFT JOIN street
	ON CAST(street.usrn AS VARCHAR) = CAST(llpg.usrn AS VARCHAR)
LEFT JOIN (
		SELECT * 
		FROM "parking-raw-zone"."ltn_london_fields"
		WHERE import_date = (
				SELECT MAX(import_date)
				FROM "parking-raw-zone"."ltn_london_fields"
			)
	) ltn
	ON ltn.uprn = p.uprn
;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
