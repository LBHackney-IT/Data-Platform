"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_eta_decision_records_pcn_dispute_gds"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
--> "dataplatform-prod-liberator-refined-zone"."parking_eta_decision_records_pcn_dispute_gds"
--< Orchestration depends upon "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full"
--< Note "import_date" is unsynchronized across all source tables so may be misaligned if unchecked by orchestration.
/*23/03/2022 - created feed
 07/04/2022 - added field for pcn stacking/grouping if pcn disputed/eta or not - added flags for HQ records as 'HQ_SiDEM_PCN' - updated join to match pcns with end special chars
 */
WITH er AS (
    SELECT case_reference,
        name,
        pcn AS er_pcn,
        hearing_type,
        case_status,
        decision_i_e_dnc_appeal_allowed_appeal_rejected,
        review_flag,
        reporting_period,
        month_year,
        import_datetime AS er_import_datetime,
        import_timestamp AS er_import_timestamp,
        import_year AS er_import_year,
        import_month AS er_import_month,
        import_day AS er_import_day,
        import_date AS er_import_date
    FROM "parking-raw-zone"."parking_eta_decision_records" -- in place of "eta_decision_records"
    WHERE import_date = (
            SELECT MAX(import_date)
            FROM "parking-raw-zone"."parking_eta_decision_records" -- in place of "eta_decision_records"
        )
),
eta_recs AS (
    SELECT pcn AS etar_pcn,
        SUM(
            CASE
                WHEN decision_i_e_dnc_appeal_allowed_appeal_rejected IN ('Appeal Rejected', 'Appeal Refused') THEN 1
                ELSE 0
            END
        ) AS appeal_rejected,
        SUM(
            CASE
                WHEN decision_i_e_dnc_appeal_allowed_appeal_rejected IN ('Appeal Allowed', 'appeal Allowed') THEN 1
                ELSE 0
            END
        ) AS appeal_allowed,
        SUM(
            CASE
                WHEN decision_i_e_dnc_appeal_allowed_appeal_rejected IN ('DNC', 'dnc') THEN 1
                ELSE 0
            END
        ) AS appeal_dnc,
        SUM(
            CASE
                WHEN decision_i_e_dnc_appeal_allowed_appeal_rejected IN ('Appeal with Direction', 'Direction') THEN 1
                ELSE 0
            END
        ) AS appeal_with_direction
    FROM "parking-raw-zone"."parking_eta_decision_records" -- in place of "eta_decision_records"
    WHERE import_date = (
            SELECT MAX(import_date)
            FROM "parking-raw-zone"."parking_eta_decision_records" -- in place of "eta_decision_records"
        )
    GROUP BY pcn
),
Disputes AS (
    SELECT ticketserialnumber,
        COUNT(DISTINCT ticketserialnumber) AS TotalpcnDisputed,
        COUNT(ticketserialnumber) AS TotalDisputed,
        /*--       liberator_pcn_ic.Serviceable,
         cast(substr(liberator_pcn_ic.date_received, 1, 10) as date)         as date_received,
         cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date) as response_generated_at,
         concat(substr(Cast(liberator_pcn_ic.date_received as varchar(10)),1, 7), '-01') as MonthYear,
         concat(substr(Cast(liberator_pcn_ic.response_generated_at as varchar(10)),1, 7), '-01') as response_MonthYear,
         date_diff('day', cast(substr(liberator_pcn_ic.date_received, 1, 10) as date), cast(substr(liberator_pcn_ic.response_generated_at, 1, 10) as date))  as ResponseDays
         */
        import_date AS dispute_import_date
    FROM "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic"
    WHERE import_date = (
            SELECT MAX(import_date)
            FROM "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic"
        )
        AND date_received != ''
        AND response_generated_at != ''
        AND LENGTH(ticketserialnumber) = 10
        AND Serviceable IN (
            'Challenges',
            'Key worker',
            'Removals',
            'TOL',
            'Charge certificate',
            'Representations'
        )
    GROUP BY ticketserialnumber,
        import_date
),
pcn AS (
    SELECT *
    FROM "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full"
    WHERE import_date = (
            SELECT MAX(import_date)
            FROM "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full"
        )
),
transform AS (
    SELECT DISTINCT CASE
            WHEN ZONE LIKE 'Estates' THEN usrn
            WHEN UPPER(SUBSTR(er.er_pcn, 1, 2)) = 'HQ' THEN 'HQ_SiDEM_PCN'
            ELSE ZONE
        END AS r_zone,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks' THEN 'onstreet'
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            ) THEN 'Estates'
            WHEN debttype LIKE 'CCTV%' THEN 'CCTV'
            WHEN ZONE LIKE 'Car Parks' THEN 'Car Parks'
            WHEN UPPER(SUBSTR(er.er_pcn, 1, 2)) = 'HQ' THEN 'HQ_SiDEM_PCN'
            ELSE debttype
        END AS pcn_type,
        /* LTN Camera/location list as of 15/03/2022 - https://docs.google.com/spreadsheets/d/12_QqvToXPAMMLRMUQpQtwJg9gRZR0vMs_LQghhdwiYw*/
        CASE
            WHEN street_location = 'Allen Road' THEN 'YB1052 - Allen Road'
            WHEN street_location = 'Ashenden Road junction of Glyn Road' THEN 'LW2205 - Ashenden Road'
            WHEN street_location = 'Barnabas Road JCT Berger Road' THEN 'LW2204 - Barnabas Road'
            WHEN street_location = 'Barnabas Road JCT Oriel Road' THEN 'LW2204 - Barnabas Road'
            WHEN street_location = 'Benthal Road' THEN 'LW2206 - Benthal Road'
            WHEN street_location = 'Bouverie Road junction of Stoke Newington Church Street' THEN 'LW2593 - Bouverie Road'
            WHEN street_location = 'Clissold Crescent' THEN 'LW2397 - Clissold Crescent'
            WHEN street_location = 'Cremer Street' THEN 'LW2041 - Cremer Street'
            WHEN street_location = 'Downs Road' THEN 'LW2389 - Downs Road'
            WHEN street_location = 'Elsdale Street' THEN 'LW2393 - Elsdale Street'
            WHEN street_location = 'Gore Road junction of Lauriston Road.' THEN 'LW2078 - Gore Road'
            WHEN street_location = 'Hyde Road' THEN 'LW2208 - Hyde Road'
            WHEN street_location = 'Hyde Road JCT Northport Street' THEN 'LW2208 - Hyde Road'
            WHEN street_location = 'Lee Street junction of Stean Street' THEN 'LW1535 - Lee Street'
            WHEN street_location = 'Loddiges Road jct Frampton Park Road' THEN 'LW1051 - Loddiges Road'
            WHEN street_location = 'Lordship Road junction of Lordship Terrace' THEN 'LW2590 - Lordship Road'
            WHEN street_location = 'Maury Road junction of Evering Road' THEN 'LW2390 - Maury Road'
            WHEN street_location = 'Mead Place' THEN 'LW2395 - Mead Place'
            WHEN street_location = 'Meeson Street junction of Kingsmead Way' THEN 'LW2079 - Meeson Street'
            WHEN street_location = 'Mount Pleasant Lane' THEN 'LW2391 - Mount Pleasant Lane'
            WHEN street_location = 'Nevill Road junction of Barbauld Road' THEN 'LW2595 - Nevill Road/ Barbauld Road'
            WHEN street_location = 'Nevill Road junction of Osterley Road' THEN 'LW0633 - Nevill Road (Osterley Road)'
            WHEN street_location = 'Neville Road junction of Osterley Road' THEN 'LW0633 - Nevill Road (Osterley Road)'
            WHEN street_location = 'Oldfield Road (E)' THEN 'LW2596 - Oldfield Road'
            WHEN street_location = 'Oldfield Road junction of Kynaston Road' THEN 'LW2596 - Oldfield Road'
            WHEN street_location = 'Pitfield Street (F)' THEN 'LW2207 - Pitfield Street'
            WHEN street_location = 'Pitfield Street JCT Hemsworth Street' THEN 'LW2207 - Pitfield Street'
            WHEN street_location = 'Powell Road junction of Kenninghall Road' THEN 'LW1691 - Powell Road (Kenninghall Road)'
            WHEN street_location = 'Shepherdess Walk' THEN 'LW2076 - Shepherdess Walk'
            WHEN street_location = 'Shore Place' THEN 'Mobile camera car - Shore Place'
            WHEN street_location = 'Stoke Newington Church Street junction of Lordship Road - Eastbound' THEN 'LW2591 - Stoke Newington Church Street eastbound'
            WHEN street_location = 'Stoke Newington Church Street junction of Marton Road - Westbound' THEN 'LW2592 - Stoke Newington Church Street westbound'
            WHEN street_location = 'Ufton Road junction of Downham Road' THEN 'LW2077 - Ufton Road'
            WHEN street_location = 'Wayland Avenue' THEN 'LW2392 - Wayland Avenue'
            WHEN street_location = 'Weymouth Terrace junction of Dunloe Street' THEN 'Mobile camera car - Weymouth Terrace'
            WHEN street_location = 'Wilton Way junction of Greenwood Road' THEN 'LW1457 - Wilton Way'
            WHEN street_location = 'Woodberry Grove junction of Rowley Gardens' THEN 'LW1457 - Woodberry Grove'
            WHEN street_location = 'Woodberry Grove junction of Seven Sisters Road' THEN 'LW1457 - Woodberry Grove'
            WHEN street_location = 'Yoakley Road junction of Stoke Newington Church Street' THEN 'LW2594 - Yoakley Road'
            ELSE 'NOT current LTN Camera Location'
        END AS ltn_camera_location,
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0 THEN 1
            ELSE 0
        END AS kpi_pcns,
        /*PCNs by Type with VDA's excluded before and included after 1st June 2021*/
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0 THEN 1
            ELSE 0
        END AS Flg_kpi_onstreet_carparks,
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0 THEN 1
            ELSE 0
        END AS Flg_kpi_Estates,
        CASE
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0 THEN 1
            ELSE 0
        END AS Flg_kpi_CCTV,
        CASE
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0 THEN 1
            ELSE 0
        END AS Flg_kpi_Car_Parks,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0 THEN 1
            ELSE 0
        END AS Flg_kpi_onstreet,
        -- Disputed pcns and by pcn type
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (isvda = 0)
            AND (isvoid = 0)
            AND (warningflag = 0)
            AND Disputes.ticketserialnumber IS NOT NULL THEN 1
            ELSE 0
        END Flg_kpi_onstreet_carparks_disputes,
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (isvda = 0)
            AND (isvoid = 0)
            AND (warningflag = 0)
            AND Disputes.ticketserialnumber IS NOT NULL THEN 1
            ELSE 0
        END Flag_kpi_Estates_disputes,
        CASE
            WHEN (debttype LIKE 'CCTV%')
            AND (isvda = 0)
            AND (isvoid = 0)
            AND (warningflag = 0)
            AND Disputes.ticketserialnumber IS NOT NULL THEN 1
            ELSE 0
        END AS Flag_kpi_CCTV_disputes,
        CASE
            WHEN (ZONE LIKE 'Car Parks')
            AND (isvda = 0)
            AND (isvoid = 0)
            AND (warningflag = 0)
            AND Disputes.ticketserialnumber IS NOT NULL THEN 1
            ELSE 0
        END AS Flag_kpi_Car_Parks_disputes,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (isvda = 0)
            AND (isvoid = 0)
            AND (warningflag = 0)
            AND Disputes.ticketserialnumber IS NOT NULL THEN 1
            ELSE 0
        END AS Flg_kpi_onstreet_disputes,
        /*onstreet_carparks ETA Decisions*/
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0 THEN eta_recs.appeal_rejected
            ELSE 0
        END AS Flg_decision_appeal_rejected_onstreet_carparks,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0 THEN eta_recs.appeal_allowed
            ELSE 0
        END AS Flg_decision_appeal_allowed_onstreet_carparks,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0 THEN eta_recs.appeal_dnc
            ELSE 0
        END AS Flg_decision_appeal_dnc_onstreet_carparks,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0 THEN eta_recs.appeal_with_direction
            ELSE 0
        END AS Flg_decision_appeal_with_direction_onstreet_carparks,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                eta_recs.appeal_rejected > 0
                OR eta_recs.appeal_allowed > 0
                OR eta_recs.appeal_dnc > 0
                OR eta_recs.appeal_with_direction > 0
            ) THEN (
                eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction
            )
            ELSE 0
        END AS Flg_eta_decision_onstreet_carparks,
        /*Estates ETA Decisions*/
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0 THEN eta_recs.appeal_rejected
            ELSE 0
        END AS Flg_decision_appeal_rejected_Estates,
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0 THEN eta_recs.appeal_allowed
            ELSE 0
        END AS Flg_decision_appeal_allowed_Estates,
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0 THEN eta_recs.appeal_dnc
            ELSE 0
        END AS Flg_decision_appeal_dnc_Estates,
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0 THEN eta_recs.appeal_with_direction
            ELSE 0
        END AS Flg_decision_appeal_with_direction_Estates,
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                eta_recs.appeal_rejected > 0
                OR eta_recs.appeal_allowed > 0
                OR eta_recs.appeal_dnc > 0
                OR eta_recs.appeal_with_direction > 0
            ) THEN (
                eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction
            )
            ELSE 0
        END AS Flg_eta_decision_Estates,
        /*CCTV ETA Decisions*/
        CASE
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0 THEN eta_recs.appeal_rejected
            ELSE 0
        END AS Flg_decision_appeal_rejected_CCTV,
        CASE
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0 THEN eta_recs.appeal_allowed
            ELSE 0
        END AS Flg_decision_appeal_allowed_CCTV,
        CASE
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0 THEN eta_recs.appeal_dnc
            ELSE 0
        END AS Flg_decision_appeal_dnc_CCTV,
        CASE
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0 THEN eta_recs.appeal_with_direction
            ELSE 0
        END AS Flg_decision_appeal_with_direction_CCTV,
        CASE
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                eta_recs.appeal_rejected > 0
                OR eta_recs.appeal_allowed > 0
                OR eta_recs.appeal_dnc > 0
                OR eta_recs.appeal_with_direction > 0
            ) THEN (
                eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction
            )
            ELSE 0
        END AS Flg_eta_decision_CCTV,
        /*Car_Parks ETA Decisions*/
        CASE
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0 THEN eta_recs.appeal_rejected
            ELSE 0
        END AS Flg_decision_appeal_rejected_Car_Parks,
        CASE
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0 THEN eta_recs.appeal_allowed
            ELSE 0
        END AS Flg_decision_appeal_allowed_Car_Parks,
        CASE
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0 THEN eta_recs.appeal_dnc
            ELSE 0
        END AS Flg_decision_appeal_dnc_Car_Parks,
        CASE
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0 THEN eta_recs.appeal_with_direction
            ELSE 0
        END AS Flg_decision_appeal_with_direction_Car_Parks,
        CASE
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                eta_recs.appeal_rejected > 0
                OR eta_recs.appeal_allowed > 0
                OR eta_recs.appeal_dnc > 0
                OR eta_recs.appeal_with_direction > 0
            ) THEN (
                eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction
            )
            ELSE 0
        END AS Flg_eta_decision_Car_Parks,
        /*onstreet ETA Decisions*/
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0 THEN eta_recs.appeal_rejected
            ELSE 0
        END AS Flg_decision_appeal_rejected_onstreet,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0 THEN eta_recs.appeal_allowed
            ELSE 0
        END AS Flg_decision_appeal_allowed_onstreet,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0 THEN eta_recs.appeal_dnc
            ELSE 0
        END AS Flg_decision_appeal_dnc_onstreet,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0 THEN eta_recs.appeal_with_direction
            ELSE 0
        END AS Flg_decision_appeal_with_direction_onstreet,
        CASE
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                eta_recs.appeal_rejected > 0
                OR eta_recs.appeal_allowed > 0
                OR eta_recs.appeal_dnc > 0
                OR eta_recs.appeal_with_direction > 0
            ) THEN (
                eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction
            )
            ELSE 0
        END AS Flg_eta_decision_onstreet,
        /* All kpi ETA Decisions*/
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0 THEN eta_recs.appeal_rejected
            ELSE 0
        END AS Flg_decision_appeal_rejected_all_kpi,
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0 THEN eta_recs.appeal_allowed
            ELSE 0
        END AS Flg_decision_appeal_allowed_all_kpi,
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0 THEN eta_recs.appeal_dnc
            ELSE 0
        END AS Flg_decision_appeal_dnc_all_kpi,
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0 THEN eta_recs.appeal_with_direction
            ELSE 0
        END AS Flg_decision_appeal_with_direction_all_kpi,
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                eta_recs.appeal_rejected > 0
                OR eta_recs.appeal_allowed > 0
                OR eta_recs.appeal_dnc > 0
                OR eta_recs.appeal_with_direction > 0
            ) THEN (
                eta_recs.appeal_rejected + eta_recs.appeal_allowed + eta_recs.appeal_dnc + eta_recs.appeal_with_direction
            )
            ELSE 0
        END AS Flg_eta_decision_all_kpi,
        /*PCNs catergorised not eta or disputed for stacking*/
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NULL THEN 'Not dispute or eta'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'disputed'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected = 0
            AND eta_recs.appeal_allowed = 0
            AND eta_recs.appeal_dnc = 0
            AND eta_recs.appeal_with_direction > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'eta with direction'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected = 0
            AND eta_recs.appeal_allowed = 0
            AND eta_recs.appeal_with_direction = 0
            AND eta_recs.appeal_dnc > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'eta dnc'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected = 0
            AND eta_recs.appeal_dnc = 0
            AND eta_recs.appeal_with_direction = 0
            AND eta_recs.appeal_allowed > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'eta allowed'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed = 0
            AND eta_recs.appeal_dnc = 0
            AND eta_recs.appeal_with_direction = 0
            AND eta_recs.appeal_rejected > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'eta rejected'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'disputed and eta with direction'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'disputed and eta dnc'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'disputed and eta allowed'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'disputed and eta rejected'
            ELSE 'NOT KPI'
        END AS kpi_pcn_dispute_eta_group,
        CASE
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected = 0
            AND eta_recs.appeal_allowed = 0
            AND eta_recs.appeal_dnc = 0
            AND eta_recs.appeal_with_direction > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected = 0
            AND eta_recs.appeal_allowed = 0
            AND eta_recs.appeal_with_direction = 0
            AND eta_recs.appeal_dnc > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected = 0
            AND eta_recs.appeal_dnc = 0
            AND eta_recs.appeal_with_direction = 0
            AND eta_recs.appeal_allowed > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed = 0
            AND eta_recs.appeal_dnc = 0
            AND eta_recs.appeal_with_direction = 0
            AND eta_recs.appeal_rejected > 0
            AND Disputes.ticketserialnumber IS NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_with_direction > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_dnc > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_allowed > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'Y'
            WHEN (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND eta_recs.appeal_rejected > 0
            AND Disputes.ticketserialnumber IS NOT NULL THEN 'Y'
            ELSE 'N'
        END AS kpi_pcn_dispute_eta_flag,
        /*PCNs not eta or disputed*/
        CASE
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NULL THEN 'Estates'
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NULL THEN 'CCTV'
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NULL THEN 'Car_Parks'
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected = 0
                    AND eta_recs.appeal_allowed = 0
                    AND eta_recs.appeal_dnc = 0
                    AND eta_recs.appeal_with_direction = 0
                )
                OR (
                    eta_recs.appeal_rejected IS NULL
                    AND eta_recs.appeal_allowed IS NULL
                    AND eta_recs.appeal_dnc IS NULL
                    AND eta_recs.appeal_with_direction IS NULL
                )
            )
            AND Disputes.ticketserialnumber IS NULL THEN 'onstreet'
            /*disputed by kpi pcn type*/
            WHEN (
                (ZONE LIKE 'Estates')
                OR (street_location LIKE '%Estate%')
                OR (usrn LIKE 'Z%')
            )
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected > 0
                    OR eta_recs.appeal_allowed > 0
                    OR eta_recs.appeal_dnc > 0
                    OR eta_recs.appeal_with_direction > 0
                )
                OR (Disputes.ticketserialnumber IS NOT NULL)
            ) THEN 'Estates - disputed_eta'
            WHEN debttype LIKE 'CCTV%'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected > 0
                    OR eta_recs.appeal_allowed > 0
                    OR eta_recs.appeal_dnc > 0
                    OR eta_recs.appeal_with_direction > 0
                )
                OR (Disputes.ticketserialnumber IS NOT NULL)
            ) THEN 'CCTV - disputed_eta'
            WHEN ZONE LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected > 0
                    OR eta_recs.appeal_allowed > 0
                    OR eta_recs.appeal_dnc > 0
                    OR eta_recs.appeal_with_direction > 0
                )
                OR (Disputes.ticketserialnumber IS NOT NULL)
            ) THEN 'Car_Parks - disputed_eta'
            WHEN debttype NOT LIKE 'CCTV%'
            AND ZONE NOT LIKE 'Estates'
            AND street_location NOT LIKE '%Estate%'
            AND usrn NOT LIKE 'Z%'
            AND ZONE NOT LIKE 'Car Parks'
            AND (
                (
                    isvda = 0
                    AND CAST(pcnissuedate AS DATE) < CAST('2021-06-01' AS DATE)
                )
                OR (
                    CAST(pcnissuedate AS DATE) > CAST('2021-05-31' AS DATE)
                )
            )
            AND isvoid = 0
            AND warningflag = 0
            AND (
                (
                    eta_recs.appeal_rejected > 0
                    OR eta_recs.appeal_allowed > 0
                    OR eta_recs.appeal_dnc > 0
                    OR eta_recs.appeal_with_direction > 0
                )
                OR (Disputes.ticketserialnumber IS NOT NULL)
            ) THEN 'onstreet - disputed_eta'
            ELSE 'NOT KPI'
        END AS kpi_pcn_not_dispute_eta_name,
        *
        /*** Collect all columns from the source tables including columns we don't yet know about. ***/
    FROM er
        LEFT JOIN eta_recs ON SUBSTR(eta_recs.etar_pcn, 1, 10) = SUBSTR(er.er_pcn, 1, 10)
        LEFT JOIN Disputes ON Disputes.ticketserialnumber = SUBSTR(er.er_pcn, 1, 10)
        LEFT JOIN pcn ON SUBSTR(er.er_pcn, 1, 10) = pcn.pcn
)
SELECT -- To mitigate future side effects from * wildcard columns in the legacy queries above, the following query
    -- explicitly define the output columns with data types cast to exactly match the existing target table...
    --> "dataplatform-prod-liberator-refined-zone"."parking_eta_decision_records_pcn_dispute_gds"
    CAST(r_zone AS VARCHAR) AS r_zone,
    -->string
    CAST(pcn_type AS VARCHAR) AS pcn_type,
    -->string
    CAST(ltn_camera_location AS VARCHAR) AS ltn_camera_location,
    -->string
    CAST(flg_kpi_onstreet_carparks AS INTEGER) AS flg_kpi_onstreet_carparks,
    -->int
    CAST(flg_kpi_estates AS INTEGER) AS flg_kpi_estates,
    -->int
    CAST(flg_kpi_cctv AS INTEGER) AS flg_kpi_cctv,
    -->int
    CAST(flg_kpi_car_parks AS INTEGER) AS flg_kpi_car_parks,
    -->int
    CAST(flg_kpi_onstreet AS INTEGER) AS flg_kpi_onstreet,
    -->int
    CAST(flg_kpi_onstreet_carparks_disputes AS INTEGER) AS flg_kpi_onstreet_carparks_disputes,
    -->int
    CAST(flag_kpi_estates_disputes AS INTEGER) AS flag_kpi_estates_disputes,
    -->int
    CAST(flag_kpi_cctv_disputes AS INTEGER) AS flag_kpi_cctv_disputes,
    -->int
    CAST(flag_kpi_car_parks_disputes AS INTEGER) AS flag_kpi_car_parks_disputes,
    -->int
    CAST(flg_kpi_onstreet_disputes AS INTEGER) AS flg_kpi_onstreet_disputes,
    -->int
    CAST(
        flg_decision_appeal_rejected_onstreet_carparks AS BIGINT
    ) AS flg_decision_appeal_rejected_onstreet_carparks,
    -->bigint
    CAST(
        flg_decision_appeal_allowed_onstreet_carparks AS BIGINT
    ) AS flg_decision_appeal_allowed_onstreet_carparks,
    -->bigint
    CAST(
        flg_decision_appeal_dnc_onstreet_carparks AS BIGINT
    ) AS flg_decision_appeal_dnc_onstreet_carparks,
    -->bigint
    CAST(
        flg_decision_appeal_with_direction_onstreet_carparks AS BIGINT
    ) AS flg_decision_appeal_with_direction_onstreet_carparks,
    -->bigint
    CAST(flg_eta_decision_onstreet_carparks AS BIGINT) AS flg_eta_decision_onstreet_carparks,
    -->bigint
    CAST(flg_decision_appeal_rejected_estates AS BIGINT) AS flg_decision_appeal_rejected_estates,
    -->bigint
    CAST(flg_decision_appeal_allowed_estates AS BIGINT) AS flg_decision_appeal_allowed_estates,
    -->bigint
    CAST(flg_decision_appeal_dnc_estates AS BIGINT) AS flg_decision_appeal_dnc_estates,
    -->bigint
    CAST(
        flg_decision_appeal_with_direction_estates AS BIGINT
    ) AS flg_decision_appeal_with_direction_estates,
    -->bigint
    CAST(flg_eta_decision_estates AS BIGINT) AS flg_eta_decision_estates,
    -->bigint
    CAST(flg_decision_appeal_rejected_cctv AS BIGINT) AS flg_decision_appeal_rejected_cctv,
    -->bigint
    CAST(flg_decision_appeal_allowed_cctv AS BIGINT) AS flg_decision_appeal_allowed_cctv,
    -->bigint
    CAST(flg_decision_appeal_dnc_cctv AS BIGINT) AS flg_decision_appeal_dnc_cctv,
    -->bigint
    CAST(
        flg_decision_appeal_with_direction_cctv AS BIGINT
    ) AS flg_decision_appeal_with_direction_cctv,
    -->bigint
    CAST(flg_eta_decision_cctv AS BIGINT) AS flg_eta_decision_cctv,
    -->bigint
    CAST(flg_decision_appeal_rejected_car_parks AS BIGINT) AS flg_decision_appeal_rejected_car_parks,
    -->bigint
    CAST(flg_decision_appeal_allowed_car_parks AS BIGINT) AS flg_decision_appeal_allowed_car_parks,
    -->bigint
    CAST(flg_decision_appeal_dnc_car_parks AS BIGINT) AS flg_decision_appeal_dnc_car_parks,
    -->bigint
    CAST(
        flg_decision_appeal_with_direction_car_parks AS BIGINT
    ) AS flg_decision_appeal_with_direction_car_parks,
    -->bigint
    CAST(flg_eta_decision_car_parks AS BIGINT) AS flg_eta_decision_car_parks,
    -->bigint
    CAST(flg_decision_appeal_rejected_onstreet AS BIGINT) AS flg_decision_appeal_rejected_onstreet,
    -->bigint
    CAST(flg_decision_appeal_allowed_onstreet AS BIGINT) AS flg_decision_appeal_allowed_onstreet,
    -->bigint
    CAST(flg_decision_appeal_dnc_onstreet AS BIGINT) AS flg_decision_appeal_dnc_onstreet,
    -->bigint
    CAST(
        flg_decision_appeal_with_direction_onstreet AS BIGINT
    ) AS flg_decision_appeal_with_direction_onstreet,
    -->bigint
    CAST(flg_eta_decision_onstreet AS BIGINT) AS flg_eta_decision_onstreet,
    -->bigint
    CAST(flg_decision_appeal_rejected_all_kpi AS BIGINT) AS flg_decision_appeal_rejected_all_kpi,
    -->bigint
    CAST(flg_decision_appeal_allowed_all_kpi AS BIGINT) AS flg_decision_appeal_allowed_all_kpi,
    -->bigint
    CAST(flg_decision_appeal_dnc_all_kpi AS BIGINT) AS flg_decision_appeal_dnc_all_kpi,
    -->bigint
    CAST(
        flg_decision_appeal_with_direction_all_kpi AS BIGINT
    ) AS flg_decision_appeal_with_direction_all_kpi,
    -->bigint
    CAST(flg_eta_decision_all_kpi AS BIGINT) AS flg_eta_decision_all_kpi,
    -->bigint
    CAST(case_reference AS VARCHAR) AS case_reference,
    -->string
    CAST("name" AS VARCHAR) AS "name",
    -->string
    CAST(er_pcn AS VARCHAR) AS er_pcn,
    -->string
    CAST(hearing_type AS VARCHAR) AS hearing_type,
    -->string
    CAST(case_status AS VARCHAR) AS case_status,
    -->string
    CAST(
        decision_i_e_dnc_appeal_allowed_appeal_rejected AS VARCHAR
    ) AS decision_i_e_dnc_appeal_allowed_appeal_rejected,
    -->string
    CAST(review_flag AS VARCHAR) AS review_flag,
    -->string
    CAST(reporting_period AS VARCHAR) AS reporting_period,
    -->string
    CAST(month_year AS VARCHAR) AS month_year,
    -->string
    CAST(er_import_datetime AS TIMESTAMP) AS er_import_datetime,
    -->timestamp
    CAST(er_import_timestamp AS VARCHAR) AS er_import_timestamp,
    -->string
    CAST(er_import_year AS VARCHAR) AS er_import_year,
    -->string
    CAST(er_import_month AS VARCHAR) AS er_import_month,
    -->string
    CAST(er_import_day AS VARCHAR) AS er_import_day,
    -->string
    CAST(er_import_date AS VARCHAR) AS er_import_date,
    -->string
    CAST(etar_pcn AS VARCHAR) AS etar_pcn,
    -->string
    CAST(appeal_rejected AS BIGINT) AS appeal_rejected,
    -->bigint
    CAST(appeal_allowed AS BIGINT) AS appeal_allowed,
    -->bigint
    CAST(appeal_dnc AS BIGINT) AS appeal_dnc,
    -->bigint
    CAST(appeal_with_direction AS BIGINT) AS appeal_with_direction,
    -->bigint
    CAST(ticketserialnumber AS VARCHAR) AS ticketserialnumber,
    -->string
    CAST(totalpcndisputed AS BIGINT) AS totalpcndisputed,
    -->bigint
    CAST(totaldisputed AS BIGINT) AS totaldisputed,
    -->bigint
    CAST(dispute_import_date AS VARCHAR) AS dispute_import_date,
    -->string
    CAST(pcn AS VARCHAR) AS pcn,
    -->string
    CAST(pcnissuedate AS DATE) AS pcnissuedate,
    -->date
    CAST(pcnissuedatetime AS TIMESTAMP) AS pcnissuedatetime,
    -->timestamp
    CAST(pcn_canx_date AS DATE) AS pcn_canx_date,
    -->date
    CAST(cancellationgroup AS VARCHAR) AS cancellationgroup,
    -->string
    CAST(cancellationreason AS VARCHAR) AS cancellationreason,
    -->string
    CAST(pcn_casecloseddate AS DATE) AS pcn_casecloseddate,
    -->date
    CAST(street_location AS VARCHAR) AS street_location,
    -->string
    CAST(whereonlocation AS VARCHAR) AS whereonlocation,
    -->string
    CAST("zone" AS VARCHAR) AS "zone",
    -->string
    CAST(usrn AS VARCHAR) AS usrn,
    -->string
    CAST(contraventioncode AS VARCHAR) AS contraventioncode,
    -->string
    CAST(contraventionsuffix AS VARCHAR) AS contraventionsuffix,
    -->string
    CAST(debttype AS VARCHAR) AS debttype,
    -->string
    CAST(vrm AS VARCHAR) AS vrm,
    -->string
    CAST(vehiclemake AS VARCHAR) AS vehiclemake,
    -->string
    CAST(vehiclemodel AS VARCHAR) AS vehiclemodel,
    -->string
    CAST(vehiclecolour AS VARCHAR) AS vehiclecolour,
    -->string
    CAST(ceo AS VARCHAR) AS ceo,
    -->string
    CAST(ceodevice AS VARCHAR) AS ceodevice,
    -->string
    CAST(current_30_day_flag AS INTEGER) AS current_30_day_flag,
    -->int
    CAST(isvda AS INTEGER) AS isvda,
    -->int
    CAST(isvoid AS INTEGER) AS isvoid,
    -->int
    CAST(isremoval AS VARCHAR) AS isremoval,
    -->string
    CAST(driverseen AS VARCHAR) AS driverseen,
    -->string
    CAST(allwindows AS VARCHAR) AS allwindows,
    -->string
    CAST(parkedonfootway AS VARCHAR) AS parkedonfootway,
    -->string
    CAST(doctor AS VARCHAR) AS doctor,
    -->string
    CAST(warningflag AS INTEGER) AS warningflag,
    -->int
    CAST(progressionstage AS VARCHAR) AS progressionstage,
    -->string
    CAST(nextprogressionstage AS VARCHAR) AS nextprogressionstage,
    -->string
    CAST(nextprogressionstagestarts AS VARCHAR) AS nextprogressionstagestarts,
    -->string
    CAST(holdreason AS VARCHAR) AS holdreason,
    -->string
    CAST(lib_initial_debt_amount AS VARCHAR) AS lib_initial_debt_amount,
    -->string
    CAST(lib_payment_received AS VARCHAR) AS lib_payment_received,
    -->string
    CAST(lib_write_off_amount AS VARCHAR) AS lib_write_off_amount,
    -->string
    CAST(lib_payment_void AS VARCHAR) AS lib_payment_void,
    -->string
    CAST(lib_payment_method AS VARCHAR) AS lib_payment_method,
    -->string
    CAST(lib_payment_ref AS VARCHAR) AS lib_payment_ref,
    -->string
    CAST(baliff_from AS VARCHAR) AS baliff_from,
    -->string
    CAST(bailiff_to AS VARCHAR) AS bailiff_to,
    -->string
    CAST(bailiff_processedon AS TIMESTAMP) AS bailiff_processedon,
    -->timestamp
    CAST(bailiff_redistributionreason AS VARCHAR) AS bailiff_redistributionreason,
    -->string
    CAST(bailiff AS VARCHAR) AS bailiff,
    -->string
    CAST(warrantissuedate AS TIMESTAMP) AS warrantissuedate,
    -->timestamp
    CAST(allocation AS INTEGER) AS allocation,
    -->int
    CAST(eta_datenotified AS TIMESTAMP) AS eta_datenotified,
    -->timestamp
    CAST(eta_packsubmittedon AS TIMESTAMP) AS eta_packsubmittedon,
    -->timestamp
    CAST(eta_evidencedate AS TIMESTAMP) AS eta_evidencedate,
    -->timestamp
    CAST(eta_adjudicationdate AS TIMESTAMP) AS eta_adjudicationdate,
    -->timestamp
    CAST(eta_appealgrounds AS VARCHAR) AS eta_appealgrounds,
    -->string
    CAST(eta_decisionreceived AS TIMESTAMP) AS eta_decisionreceived,
    -->timestamp
    CAST(eta_outcome AS VARCHAR) AS eta_outcome,
    -->string
    CAST(eta_packsubmittedby AS VARCHAR) AS eta_packsubmittedby,
    -->string
    CAST(cancelledby AS VARCHAR) AS cancelledby,
    -->string
    CAST(registered_keeper_address AS VARCHAR) AS registered_keeper_address,
    -->string
    CAST(current_ticket_address AS VARCHAR) AS current_ticket_address,
    -->string
    CAST(corresp_dispute_flag AS INTEGER) AS corresp_dispute_flag,
    -->int
    CAST(keyworker_corresp_dispute_flag AS INTEGER) AS keyworker_corresp_dispute_flag,
    -->int
    CAST(fin_year_flag AS VARCHAR) AS fin_year_flag,
    -->string
    CAST(fin_year AS VARCHAR) AS fin_year,
    -->string
    CAST(ticket_ref AS VARCHAR) AS ticket_ref,
    -->string
    CAST(nto_printed AS TIMESTAMP) AS nto_printed,
    -->timestamp
    CAST(appeal_accepted AS TIMESTAMP) AS appeal_accepted,
    -->timestamp
    CAST(arrived_in_pound AS TIMESTAMP) AS arrived_in_pound,
    -->timestamp
    CAST(cancellation_reversed AS TIMESTAMP) AS cancellation_reversed,
    -->timestamp
    CAST(cc_printed AS TIMESTAMP) AS cc_printed,
    -->timestamp
    CAST(drr AS TIMESTAMP) AS drr,
    -->timestamp
    CAST(en_printed AS TIMESTAMP) AS en_printed,
    -->timestamp
    CAST(hold_released AS TIMESTAMP) AS hold_released,
    -->timestamp
    CAST(dvla_response AS TIMESTAMP) AS dvla_response,
    -->timestamp
    CAST(dvla_request AS TIMESTAMP) AS dvla_request,
    -->timestamp
    CAST(full_rate_uplift AS TIMESTAMP) AS full_rate_uplift,
    -->timestamp
    CAST(hold_until AS TIMESTAMP) AS hold_until,
    -->timestamp
    CAST(lifted_at AS TIMESTAMP) AS lifted_at,
    -->timestamp
    CAST(lifted_by AS TIMESTAMP) AS lifted_by,
    -->timestamp
    CAST(loaded AS TIMESTAMP) AS loaded,
    -->timestamp
    CAST(nor_sent AS TIMESTAMP) AS nor_sent,
    -->timestamp
    CAST(notice_held AS TIMESTAMP) AS notice_held,
    -->timestamp
    CAST(ofr_printed AS TIMESTAMP) AS ofr_printed,
    -->timestamp
    CAST(pcn_printed AS TIMESTAMP) AS pcn_printed,
    -->timestamp
    CAST(reissue_nto_requested AS TIMESTAMP) AS reissue_nto_requested,
    -->timestamp
    CAST(reissue_pcn AS TIMESTAMP) AS reissue_pcn,
    -->timestamp
    CAST(set_back_to_pre_cc_stage AS TIMESTAMP) AS set_back_to_pre_cc_stage,
    -->timestamp
    CAST(vehicle_released_for_auction AS TIMESTAMP) AS vehicle_released_for_auction,
    -->timestamp
    CAST(warrant_issued AS TIMESTAMP) AS warrant_issued,
    -->timestamp
    CAST(warrant_redistributed AS TIMESTAMP) AS warrant_redistributed,
    -->timestamp
    CAST(warrant_request_granted AS TIMESTAMP) AS warrant_request_granted,
    -->timestamp
    CAST(ad_hoc_vq4_request AS TIMESTAMP) AS ad_hoc_vq4_request,
    -->timestamp
    CAST(paper_vq5_received AS TIMESTAMP) AS paper_vq5_received,
    -->timestamp
    CAST(pcn_extracted_for_buslane AS TIMESTAMP) AS pcn_extracted_for_buslane,
    -->timestamp
    CAST(pcn_extracted_for_pre_debt AS TIMESTAMP) AS pcn_extracted_for_pre_debt,
    -->timestamp
    CAST(pcn_extracted_for_collection AS TIMESTAMP) AS pcn_extracted_for_collection,
    -->timestamp
    CAST(pcn_extracted_for_drr AS TIMESTAMP) AS pcn_extracted_for_drr,
    -->timestamp
    CAST(pcn_extracted_for_cc AS TIMESTAMP) AS pcn_extracted_for_cc,
    -->timestamp
    CAST(pcn_extracted_for_nto AS TIMESTAMP) AS pcn_extracted_for_nto,
    -->timestamp
    CAST(pcn_extracted_for_print AS TIMESTAMP) AS pcn_extracted_for_print,
    -->timestamp
    CAST(warning_notice_extracted_for_print AS TIMESTAMP) AS warning_notice_extracted_for_print,
    -->timestamp
    CAST(pcn_extracted_for_ofr AS TIMESTAMP) AS pcn_extracted_for_ofr,
    -->timestamp
    CAST(pcn_extracted_for_warrant_request AS TIMESTAMP) AS pcn_extracted_for_warrant_request,
    -->timestamp
    CAST(pre_debt_new_debtor_details AS TIMESTAMP) AS pre_debt_new_debtor_details,
    -->timestamp
    CAST(importdattime AS TIMESTAMP) AS importdattime,
    -->timestamp
    CAST(importdatetime AS TIMESTAMP) AS importdatetime,
    -->timestamp
    CAST(kpi_pcns AS INTEGER) AS kpi_pcns,
    -->int
    CAST(kpi_pcn_dispute_eta_group AS VARCHAR) AS kpi_pcn_dispute_eta_group,
    -->string
    CAST(kpi_pcn_dispute_eta_flag AS VARCHAR) AS kpi_pcn_dispute_eta_flag,
    -->string
    CAST(kpi_pcn_not_dispute_eta_name AS VARCHAR) AS kpi_pcn_not_dispute_eta_name,
    -->string
    CAST(import_year AS VARCHAR) AS import_year,
    -->string
    CAST(import_month AS VARCHAR) AS import_month,
    -->string
    CAST(import_day AS VARCHAR) AS import_day,
    -->string
    CAST(import_date AS VARCHAR) AS import_date --, -->string
FROM transform;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
