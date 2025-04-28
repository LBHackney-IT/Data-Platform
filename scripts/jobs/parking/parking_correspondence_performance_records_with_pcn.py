"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_correspondence_performance_records_with_pcn"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
/* 
parking_correspondence_performance_records_with_pcn.sql
Correspondence Performance records last 13 months with PCN FOI records

-->> "dataplatform-prod-liberator-refined-zone"."parking_correspondence_performance_records_with_pcn"
--<< "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full"
-- < "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic"
-- < "parking-raw-zone"."parking_correspondence_performance_teams"

16/06/2022 - Created 
21/04/2023 - added teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing
27/02/2025 - Refactored SQL for migration back to AthenaSQL for dap-airflow
14/04/2025 - Strictly applied column formatting consistent with previous Glue outputs.
16/04/2025 - Workaround to orchestration issue caused by latest "pcnfoidetails_pcn_foi_full" not yet ready
*/
WITH
team AS (
    SELECT DISTINCT
        "start_date" AS t_start_date,
        end_date AS t_end_date,
        team AS t_team,
        team_name AS t_team_name,
        "role" AS t_role,
        forename AS t_forename,
        surname AS t_surname,
        full_name AS t_full_name,
        qa_doc_created_by AS t_qa_doc_created_by,
        qa_doc_full_name AS t_qa_doc_full_name,
        post_title AS t_post_title,
        notes AS t_notes,
        import_date AS t_import_date 
    FROM "parking-raw-zone"."parking_correspondence_performance_teams"
    WHERE import_date IN (
            SELECT MAX(g.import_date) AS import_date
            FROM "parking-raw-zone"."parking_correspondence_performance_teams" g
        )
),
liberator AS (
    SELECT *,

        CAST(CURRENT_TIMESTAMP AS TIMESTAMP(3)) AS current_utc_timestamp,      
        TRY(CAST(date_received AS TIMESTAMP(3))) AS date_received_timestamp,    -- pre-filtered by WHERE clause
        
        IF(whenassigned <> '',      -- contains probable valid timestamp
            TRY(CAST(whenassigned AS TIMESTAMP(3))),
            CAST(NULL AS TIMESTAMP(3)) -- edge case
        ) AS whenassigned_timestamp,
        
        IF(Response_generated_at <> '',      -- contains probable valid timestamp
            TRY(CAST(Response_generated_at AS TIMESTAMP(3))),
            CAST(NULL AS TIMESTAMP(3)) -- edge case
        ) AS  Response_generated_at_timestamp,
        
        CAST(CASE WHEN date_received <> '' 
            THEN DATE_DIFF(
                    'day',
                    TRY_CAST(SUBSTR(date_received, 1, 10) AS DATE), -- under condition of date_received <>''
                    CURRENT_DATE
                )
            --ELSE NULL
        END AS INTEGER) AS days_since_date_received,

        CAST(CASE WHEN date_received <> '' AND whenassigned <> ''
            THEN DATE_DIFF(
                'day',
                TRY_CAST(SUBSTR(date_received, 1, 10) AS DATE), -- under condition of date_received <>''
                TRY_CAST(SUBSTR(whenassigned, 1, 10) AS DATE)
            )
            --ELSE NULL
        END AS INTEGER) AS days_since_date_received_whenassigned,

        CAST(CASE WHEN whenassigned <> '' AND response_generated_at = ''
            THEN DATE_DIFF(
                'day',
                TRY_CAST(SUBSTR(whenassigned, 1, 10) AS DATE),
                CURRENT_DATE
            )
            --ELSE NULL -- edge case
        END AS INTEGER) AS days_since_whenassigned,

        CAST(CASE WHEN whenassigned <> '' AND response_generated_at <> ''
            THEN DATE_DIFF(
                'day',
                TRY_CAST(SUBSTR(whenassigned, 1, 10) AS DATE),
                TRY_CAST(SUBSTR(response_generated_at, 1, 10) AS DATE)
            )
            --ELSE NULL -- edge case
        END AS INTEGER) AS days_since_whenassigned_response_generated_at,

        CAST(CASE WHEN date_received <> '' AND response_generated_at <> ''
            THEN DATE_DIFF(
                'day',
                TRY_CAST(SUBSTR(date_received, 1, 10) AS DATE),
                TRY_CAST(SUBSTR(response_generated_at, 1, 10) AS DATE)
            )
            --ELSE NULL -- edge case
        END AS INTEGER) AS days_since_date_received_response_generated_at

    FROM "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic" 
    WHERE import_Date IN (
            SELECT MAX(g.import_date) AS import_date
            FROM "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic" g
        )
    AND LENGTH(ticketserialnumber) = 10 -- ticket filter
    AND date_received <> ''  -- is the overriding condition for "13 months from todays date"!
    AND TRY_CAST(SUBSTR(date_received, 1, 10) AS DATE) > CURRENT_DATE - INTERVAL '13' MONTH 
        -- Last 13 months from todays date
/*      -- This alternative method captures slightly more records...
    AND DATE_DIFF(
            'month',
            TRY_CAST(SUBSTR(date_received, 1, 10) AS DATE),
            CURRENT_DATE
        ) <= 13
*/    
)
SELECT
    CAST(CASE
        WHEN l.date_received <> '' AND l.whenassigned = '' 
            THEN 'Unassigned'
        WHEN l.date_received <> '' AND l.whenassigned <> '' AND l.response_generated_at = '' 
            THEN 'Assigned'
        WHEN l.date_received <> '' AND l.whenassigned <> '' AND l.response_generated_at <> '' 
            THEN 'Responded'
        --ELSE NULL
    END AS VARCHAR) AS response_status,

    CAST(l.current_utc_timestamp AS VARCHAR) AS current_time_stamp,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned = '' 
        THEN 'INTERVAL ''' 
            || REGEXP_REPLACE(CAST(l.current_utc_timestamp - l.date_received_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
            || ''' DAY TO SECOND'
        --ELSE NULL
    END AS VARCHAR) AS unassigned_time,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned <> '' 
        THEN 'INTERVAL ''' 
            || REGEXP_REPLACE(CAST(l.whenassigned_timestamp - l.date_received_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
            || ''' DAY TO SECOND'
        --ELSE NULL
    END AS VARCHAR) AS to_assigned_time,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at = '' 
        THEN 'INTERVAL ''' 
            || REGEXP_REPLACE(CAST(l.current_utc_timestamp - l.whenassigned_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
            || ''' DAY TO SECOND'
        --ELSE NULL
    END AS VARCHAR) AS assigned_in_progress_time,
    
    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at <> '' 
        THEN 'INTERVAL ''' 
            || REGEXP_REPLACE(CAST(l.Response_generated_at_timestamp - l.whenassigned_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
            || ''' DAY TO SECOND'
        --ELSE NULL
    END AS VARCHAR) AS assigned_response_time,

    CAST(CASE WHEN l.date_received <> '' AND l.response_generated_at <> '' 
        THEN 'INTERVAL ''' 
            || REGEXP_REPLACE(CAST(l.Response_generated_at_timestamp - l.date_received_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
            || ''' DAY TO SECOND'
        --ELSE NULL
    END AS VARCHAR) AS response_time,

    /*unassigned days*/
    CAST(CASE WHEN l.whenassigned = '' 
        THEN l.days_since_date_received
        --ELSE NULL
    END AS VARCHAR) AS unassigned_days,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned = ''
        THEN 
            CASE
                WHEN l.days_since_date_received <= 5 THEN '5 or Less days'
                WHEN l.days_since_date_received BETWEEN 6 AND 14 THEN '6 to 14 days'
                WHEN l.days_since_date_received BETWEEN 15 AND 47 THEN '15 to 47 days'
                WHEN l.days_since_date_received BETWEEN 48 AND 56 THEN '48 to 56 days'
                WHEN l.days_since_date_received > 56 THEN '56 plus days'
                --WHEN l.days_since_date_received IS NULL THEN NULL -- edge case examined
                --ELSE NULL
            END
        --ELSE NULL
    END AS VARCHAR) AS unassigned_days_group,
    
    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned = ''
            AND l.days_since_date_received <= 56 
        THEN 1
        ELSE 0
    END AS INTEGER) AS unassigned_days_kpiTotFiftySixLess,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned = ''
            AND l.days_since_date_received <= 14 
        THEN 1
        ELSE 0
    END AS INTEGER) AS unassigned_days_kpiTotFourteenLess,

    /*Days to assign*/
    CAST(l.days_since_date_received_whenassigned AS VARCHAR) AS days_to_assign,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned <> ''
        THEN
            CASE
                WHEN l.days_since_date_received_whenassigned <= 5 THEN '5 or Less days'
                WHEN l.days_since_date_received_whenassigned BETWEEN 6 AND 14 THEN '6 to 14 days'
                WHEN l.days_since_date_received_whenassigned BETWEEN 15 AND 47 THEN '15 to 47 days'
                WHEN l.days_since_date_received_whenassigned BETWEEN 48 AND 56 THEN '48 to 56 days'
                WHEN l.days_since_date_received_whenassigned > 56 THEN '56 plus days'
                --WHEN l.days_since_date_received_whenassigned IS NULL THEN NULL    -- edge case examined
                --ELSE NULL
            END
        --ELSE NULL
    END AS VARCHAR) AS days_to_assign_group,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned <> ''
            AND l.days_since_date_received_whenassigned <= 56 
        THEN 1
        ELSE 0
    END AS INTEGER) AS Days_to_assign_kpiTotFiftySixLess,

    CAST(CASE WHEN l.date_received <> '' AND l.whenassigned <> ''
            AND l.days_since_date_received_whenassigned <= 14 
        THEN 1
        ELSE 0
    END AS INTEGER) AS Days_to_assign_kpiTotFourteenLess,

    /*assigned in progress days*/
    CAST(l.days_since_whenassigned AS VARCHAR) AS assigned_in_progress_days,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at = ''
        THEN
            CASE
                WHEN l.days_since_whenassigned <= 5 THEN '5 or Less days'
                WHEN l.days_since_whenassigned BETWEEN 6 AND 14 THEN '6 to 14 days'
                WHEN l.days_since_whenassigned BETWEEN 15 AND 47 THEN '15 to 47 days'
                WHEN l.days_since_whenassigned BETWEEN 48 AND 56 THEN '48 to 56 days'
                WHEN l.days_since_whenassigned > 56 THEN '56 plus days'
                --WHEN l.days_since_whenassigned IS NULL THEN NULL    -- edge case examined
                --ELSE NULL
            END
        --ELSE NULL
    END AS VARCHAR) AS assigned_in_progress_days_group,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at = ''
            AND l.days_since_whenassigned <= 56 
        THEN 1
        ELSE 0
    END AS INTEGER) AS assigned_in_progress_days_kpiTotFiftySixLess,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at = ''
            AND l.days_since_whenassigned <= 14 
        THEN 1
        ELSE 0
    END AS INTEGER) AS assigned_in_progress_days_kpiTotFourteenLess,

    /*assigned response days*/
    CAST(l.days_since_whenassigned_response_generated_at AS VARCHAR) AS assignedResponseDays,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at <> ''
        THEN
            CASE
                WHEN l.days_since_whenassigned_response_generated_at <= 5 THEN '5 or Less days'
                WHEN l.days_since_whenassigned_response_generated_at BETWEEN 6 AND 14 THEN '6 to 14 days'
                WHEN l.days_since_whenassigned_response_generated_at BETWEEN 15 AND 47 THEN '15 to 47 days'
                WHEN l.days_since_whenassigned_response_generated_at BETWEEN 48 AND 56 THEN '48 to 56 days'
                WHEN l.days_since_whenassigned_response_generated_at > 56 THEN '56 plus days'
                --WHEN l.days_since_whenassigned_response_generated_at IS NULL THEN NULL    -- edge case examined
                --ELSE NULL
            END
        --ELSE NULL
    END AS VARCHAR) AS assignedResponseDays_group,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at <> ''
            AND l.days_since_whenassigned_response_generated_at <= 56 
        THEN 1
        ELSE 0
    END AS INTEGER) AS assignedResponseDays_kpiTotFiftySixLess,

    CAST(CASE WHEN l.whenassigned <> '' AND l.response_generated_at <> ''
            AND l.days_since_whenassigned_response_generated_at <= 14 
        THEN 1
        ELSE 0
    END AS INTEGER) AS assignedResponseDays_kpiTotFourteenLess,

    /*Response days*/
    CAST(l.days_since_date_received_response_generated_at AS VARCHAR) AS ResponseDays,

    CAST(CASE WHEN l.date_received <> '' AND l.response_generated_at <> ''
        THEN
            CASE
                WHEN l.days_since_date_received_response_generated_at <= 5 THEN '5 or Less days'
                WHEN l.days_since_date_received_response_generated_at BETWEEN 6 AND 14 THEN '6 to 14 days'
                WHEN l.days_since_date_received_response_generated_at BETWEEN 15 AND 47 THEN '15 to 47 days'
                WHEN l.days_since_date_received_response_generated_at BETWEEN 48 AND 56 THEN '48 to 56 days'
                WHEN l.days_since_date_received_response_generated_at > 56 THEN '56 plus days'
                --WHEN l.days_since_date_received_response_generated_at IS NULL THEN NULL    -- edge case examined
                --ELSE NULL
            END
        --ELSE NULL
    END AS VARCHAR) AS ResponseDays_group,

    CAST(CASE WHEN l.date_received <> '' AND l.response_generated_at <> ''
            AND l.days_since_date_received_response_generated_at <= 56 
        THEN 1
        ELSE 0
    END AS INTEGER) AS ResponseDays_kpiTotFiftySixLess,

    CAST(CASE WHEN l.date_received <> '' AND l.response_generated_at <> ''
            AND l.days_since_date_received_response_generated_at <= 14 
        THEN 1
        ELSE 0
    END AS INTEGER) AS ResponseDays_kpiTotFourteenLess,

    l.Response_generated_at,    --AS VARCHAR
    l.Date_Received,            --AS VARCHAR

    CAST(SUBSTR(TRY_CAST(l.date_received AS VARCHAR(10)), 1, 7) || '-01' AS VARCHAR) AS MonthYear,
    
    l.Type AS "type",       --AS VARCHAR
    l.Serviceable,          --AS VARCHAR
    l.Service_category,     --AS VARCHAR
    l.Response_written_by,  --AS VARCHAR
    l.Letter_template,      --AS VARCHAR
    l.Action_taken,         --AS VARCHAR
    l.Related_to_PCN,       --AS VARCHAR
    l.Cancellation_group,   --AS VARCHAR
    l.Cancellation_reason,  --AS VARCHAR
    l.whenassigned,         --AS VARCHAR
    l.ticketserialnumber,   --AS VARCHAR
    l.noderef,              --AS VARCHAR
    TRY_CAST(l.record_created AS TIMESTAMP(3)) AS record_created, -- cast from VARCHAR
    l.import_timestamp,     --AS VARCHAR

    /*** pcn columns taken from "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full" ***/
    -- Data sourced from the refined zone needs to be handled carefully...
    -- Do not assume the following output column datatypes will be the same as "pcnfoidetails_pcn_foi_full".
    -- Being left-joined to "pcnfoidetails_pcn_foi_full" will cause NULLs to appear in these columns.
    -- And similar transforms elsewhere require different translations to the ones below...
    /* These are the current automated translations developed for this transform:-   
        TRY_CAST(p.[source_column] AS DATE) AS [target_column], --[position]-- try date to date
        COALESCE(DATE_FORMAT(TRY_CAST(p.[source_column] AS DATE), '%Y-%m-%d'), CAST(p.[source_column] AS VARCHAR)) AS [target_column], --[position]-- try date to string
        TRY_CAST(p.[source_column] AS INTEGER) AS [target_column], --[position]-- try int to int
        TRY_CAST(p.[source_column] AS VARCHAR) AS [target_column], --[position]-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.[source_column] AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.[source_column] AS VARCHAR)) AS [target_column], --[position]-- try timestamp to string
        TRY_CAST(p.[source_column] AS TIMESTAMP) AS [target_column], --[position]-- try timestamp to timestamp
    */
    -- These translations try to deal with problems without resorting to throwing errors, tolerating a reasonable degree of schema evolution in the "pcnfoidetails_pcn_foi_full" source.
    TRY_CAST(p.pcn AS VARCHAR) AS pcn_pcn, --45-- try string to string (default)
    TRY_CAST(p.pcnissuedate AS DATE) AS pcn_pcnissuedate, --46-- try date to date
    TRY_CAST(p.pcnissuedatetime AS TIMESTAMP) AS pcn_pcnissuedatetime, --47-- try timestamp to timestamp
    TRY_CAST(p.pcn_canx_date AS DATE) AS pcn_pcn_canx_date, --48-- try date to date
    TRY_CAST(p.cancellationgroup AS VARCHAR) AS pcn_cancellationgroup, --49-- try string to string (default)
    TRY_CAST(p.cancellationreason AS VARCHAR) AS pcn_cancellationreason, --50-- try string to string (default)
    TRY_CAST(p.pcn_casecloseddate AS DATE) AS pcn_pcn_casecloseddate, --51-- try date to date
    TRY_CAST(p.street_location AS VARCHAR) AS pcn_street_location, --52-- try string to string (default)
    TRY_CAST(p.whereonlocation AS VARCHAR) AS pcn_whereonlocation, --53-- try string to string (default)
    TRY_CAST(p.zone AS VARCHAR) AS pcn_zone, --54-- try string to string (default)
    TRY_CAST(p.usrn AS VARCHAR) AS pcn_usrn, --55-- try string to string (default)
    TRY_CAST(p.contraventioncode AS VARCHAR) AS pcn_contraventioncode, --56-- try string to string (default)
    TRY_CAST(p.contraventionsuffix AS VARCHAR) AS pcn_contraventionsuffix, --57-- try string to string (default)
    TRY_CAST(p.debttype AS VARCHAR) AS pcn_debttype, --58-- try string to string (default)
    TRY_CAST(p.vrm AS VARCHAR) AS pcn_vrm, --59-- try string to string (default)
    TRY_CAST(p.vehiclemake AS VARCHAR) AS pcn_vehiclemake, --60-- try string to string (default)
    TRY_CAST(p.vehiclemodel AS VARCHAR) AS pcn_vehiclemodel, --61-- try string to string (default)
    TRY_CAST(p.vehiclecolour AS VARCHAR) AS pcn_vehiclecolour, --62-- try string to string (default)
    TRY_CAST(p.ceo AS VARCHAR) AS pcn_ceo, --63-- try string to string (default)
    TRY_CAST(p.ceodevice AS VARCHAR) AS pcn_ceodevice, --64-- try string to string (default)
    TRY_CAST(p.current_30_day_flag AS INTEGER) AS pcn_current_30_day_flag, --65-- try int to int
    TRY_CAST(p.isvda AS INTEGER) AS pcn_isvda, --66-- try int to int
    TRY_CAST(p.isvoid AS INTEGER) AS pcn_isvoid, --67-- try int to int
    TRY_CAST(p.isremoval AS VARCHAR) AS pcn_isremoval, --68-- try string to string (default)
    TRY_CAST(p.driverseen AS VARCHAR) AS pcn_driverseen, --69-- try string to string (default)
    TRY_CAST(p.allwindows AS VARCHAR) AS pcn_allwindows, --70-- try string to string (default)
    TRY_CAST(p.parkedonfootway AS VARCHAR) AS pcn_parkedonfootway, --71-- try string to string (default)
    TRY_CAST(p.doctor AS VARCHAR) AS pcn_doctor, --72-- try string to string (default)
    TRY_CAST(p.warningflag AS INTEGER) AS pcn_warningflag, --73-- try int to int
    TRY_CAST(p.progressionstage AS VARCHAR) AS pcn_progressionstage, --74-- try string to string (default)
    TRY_CAST(p.nextprogressionstage AS VARCHAR) AS pcn_nextprogressionstage, --75-- try string to string (default)
    TRY_CAST(p.nextprogressionstagestarts AS VARCHAR) AS pcn_nextprogressionstagestarts, --76-- try string to string (default)
    TRY_CAST(p.holdreason AS VARCHAR) AS pcn_holdreason, --77-- try string to string (default)
    TRY_CAST(p.lib_initial_debt_amount AS VARCHAR) AS pcn_lib_initial_debt_amount, --78-- try string to string (default)
    TRY_CAST(p.lib_payment_received AS VARCHAR) AS pcn_lib_payment_received, --79-- try string to string (default)
    TRY_CAST(p.lib_write_off_amount AS VARCHAR) AS pcn_lib_write_off_amount, --80-- try string to string (default)
    TRY_CAST(p.lib_payment_void AS VARCHAR) AS pcn_lib_payment_void, --81-- try string to string (default)
    TRY_CAST(p.lib_payment_method AS VARCHAR) AS pcn_lib_payment_method, --82-- try string to string (default)
    TRY_CAST(p.lib_payment_ref AS VARCHAR) AS pcn_lib_payment_ref, --83-- try string to string (default)
    TRY_CAST(p.baliff_from AS VARCHAR) AS pcn_baliff_from, --84-- try string to string (default)
    TRY_CAST(p.bailiff_to AS VARCHAR) AS pcn_bailiff_to, --85-- try string to string (default)
    TRY_CAST(p.bailiff_processedon AS TIMESTAMP) AS pcn_bailiff_processedon, --86-- try timestamp to timestamp
    TRY_CAST(p.bailiff_redistributionreason AS VARCHAR) AS pcn_bailiff_redistributionreason, --87-- try string to string (default)
    TRY_CAST(p.bailiff AS VARCHAR) AS pcn_bailiff, --88-- try string to string (default)
    TRY_CAST(p.warrantissuedate AS TIMESTAMP) AS pcn_warrantissuedate, --89-- try timestamp to timestamp
    TRY_CAST(p.allocation AS INTEGER) AS pcn_allocation, --90-- try int to int
    TRY_CAST(p.eta_datenotified AS TIMESTAMP) AS pcn_eta_datenotified, --91-- try timestamp to timestamp
    TRY_CAST(p.eta_packsubmittedon AS TIMESTAMP) AS pcn_eta_packsubmittedon, --92-- try timestamp to timestamp
    TRY_CAST(p.eta_evidencedate AS TIMESTAMP) AS pcn_eta_evidencedate, --93-- try timestamp to timestamp
    TRY_CAST(p.eta_adjudicationdate AS TIMESTAMP) AS pcn_eta_adjudicationdate, --94-- try timestamp to timestamp
    TRY_CAST(p.eta_appealgrounds AS VARCHAR) AS pcn_eta_appealgrounds, --95-- try string to string (default)
    TRY_CAST(p.eta_decisionreceived AS TIMESTAMP) AS pcn_eta_decisionreceived, --96-- try timestamp to timestamp
    TRY_CAST(p.eta_outcome AS VARCHAR) AS pcn_eta_outcome, --97-- try string to string (default)
    TRY_CAST(p.eta_packsubmittedby AS VARCHAR) AS pcn_eta_packsubmittedby, --98-- try string to string (default)
    TRY_CAST(p.cancelledby AS VARCHAR) AS pcn_cancelledby, --99-- try string to string (default)
    TRY_CAST(p.registered_keeper_address AS VARCHAR) AS pcn_registered_keeper_address, --100-- try string to string (default)
    TRY_CAST(p.current_ticket_address AS VARCHAR) AS pcn_current_ticket_address, --101-- try string to string (default)
    TRY_CAST(p.corresp_dispute_flag AS INTEGER) AS pcn_corresp_dispute_flag, --102-- try int to int
    TRY_CAST(p.keyworker_corresp_dispute_flag AS INTEGER) AS pcn_keyworker_corresp_dispute_flag, --103-- try int to int
    TRY_CAST(p.fin_year_flag AS VARCHAR) AS pcn_fin_year_flag, --104-- try string to string (default)
    TRY_CAST(p.fin_year AS VARCHAR) AS pcn_fin_year, --105-- try string to string (default)
    TRY_CAST(p.ticket_ref AS VARCHAR) AS pcn_ticket_ref, --106-- try string to string (default)
    TRY_CAST(p.nto_printed AS TIMESTAMP) AS pcn_nto_printed, --107-- try timestamp to timestamp
    TRY_CAST(p.appeal_accepted AS TIMESTAMP) AS pcn_appeal_accepted, --108-- try timestamp to timestamp
    TRY_CAST(p.arrived_in_pound AS TIMESTAMP) AS pcn_arrived_in_pound, --109-- try timestamp to timestamp
    TRY_CAST(p.cancellation_reversed AS TIMESTAMP) AS pcn_cancellation_reversed, --110-- try timestamp to timestamp
    TRY_CAST(p.cc_printed AS TIMESTAMP) AS pcn_cc_printed, --111-- try timestamp to timestamp
    TRY_CAST(p.drr AS TIMESTAMP) AS pcn_drr, --112-- try timestamp to timestamp
    TRY_CAST(p.en_printed AS TIMESTAMP) AS pcn_en_printed, --113-- try timestamp to timestamp
    TRY_CAST(p.hold_released AS TIMESTAMP) AS pcn_hold_released, --114-- try timestamp to timestamp
    TRY_CAST(p.dvla_response AS TIMESTAMP) AS pcn_dvla_response, --115-- try timestamp to timestamp
    TRY_CAST(p.dvla_request AS TIMESTAMP) AS pcn_dvla_request, --116-- try timestamp to timestamp
    TRY_CAST(p.full_rate_uplift AS TIMESTAMP) AS pcn_full_rate_uplift, --117-- try timestamp to timestamp
    TRY_CAST(p.hold_until AS TIMESTAMP) AS pcn_hold_until, --118-- try timestamp to timestamp
    TRY_CAST(p.lifted_at AS TIMESTAMP) AS pcn_lifted_at, --119-- try timestamp to timestamp
    TRY_CAST(p.lifted_by AS TIMESTAMP) AS pcn_lifted_by, --120-- try timestamp to timestamp
    TRY_CAST(p.loaded AS TIMESTAMP) AS pcn_loaded, --121-- try timestamp to timestamp
    TRY_CAST(p.nor_sent AS TIMESTAMP) AS pcn_nor_sent, --122-- try timestamp to timestamp
    TRY_CAST(p.notice_held AS TIMESTAMP) AS pcn_notice_held, --123-- try timestamp to timestamp
    TRY_CAST(p.ofr_printed AS TIMESTAMP) AS pcn_ofr_printed, --124-- try timestamp to timestamp
    TRY_CAST(p.pcn_printed AS TIMESTAMP) AS pcn_pcn_printed, --125-- try timestamp to timestamp
    TRY_CAST(p.reissue_nto_requested AS TIMESTAMP) AS pcn_reissue_nto_requested, --126-- try timestamp to timestamp
    TRY_CAST(p.reissue_pcn AS TIMESTAMP) AS pcn_reissue_pcn, --127-- try timestamp to timestamp
    TRY_CAST(p.set_back_to_pre_cc_stage AS TIMESTAMP) AS pcn_set_back_to_pre_cc_stage, --128-- try timestamp to timestamp
    TRY_CAST(p.vehicle_released_for_auction AS TIMESTAMP) AS pcn_vehicle_released_for_auction, --129-- try timestamp to timestamp
    TRY_CAST(p.warrant_issued AS TIMESTAMP) AS pcn_warrant_issued, --130-- try timestamp to timestamp
    TRY_CAST(p.warrant_redistributed AS TIMESTAMP) AS pcn_warrant_redistributed, --131-- try timestamp to timestamp
    TRY_CAST(p.warrant_request_granted AS TIMESTAMP) AS pcn_warrant_request_granted, --132-- try timestamp to timestamp
    TRY_CAST(p.ad_hoc_vq4_request AS TIMESTAMP) AS pcn_ad_hoc_vq4_request, --133-- try timestamp to timestamp
    TRY_CAST(p.paper_vq5_received AS TIMESTAMP) AS pcn_paper_vq5_received, --134-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_buslane AS TIMESTAMP) AS pcn_pcn_extracted_for_buslane, --135-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_pre_debt AS TIMESTAMP) AS pcn_pcn_extracted_for_pre_debt, --136-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_collection AS TIMESTAMP) AS pcn_pcn_extracted_for_collection, --137-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_drr AS TIMESTAMP) AS pcn_pcn_extracted_for_drr, --138-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_cc AS TIMESTAMP) AS pcn_pcn_extracted_for_cc, --139-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_nto AS TIMESTAMP) AS pcn_pcn_extracted_for_nto, --140-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_print AS TIMESTAMP) AS pcn_pcn_extracted_for_print, --141-- try timestamp to timestamp
    TRY_CAST(p.warning_notice_extracted_for_print AS TIMESTAMP) AS pcn_warning_notice_extracted_for_print, --142-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_ofr AS TIMESTAMP) AS pcn_pcn_extracted_for_ofr, --143-- try timestamp to timestamp
    TRY_CAST(p.pcn_extracted_for_warrant_request AS TIMESTAMP) AS pcn_pcn_extracted_for_warrant_request, --144-- try timestamp to timestamp
    TRY_CAST(p.pre_debt_new_debtor_details AS TIMESTAMP) AS pcn_pre_debt_new_debtor_details, --145-- try timestamp to timestamp
    TRY_CAST(p.importdattime AS TIMESTAMP) AS pcn_importdattime, --146-- try timestamp to timestamp
    TRY_CAST(p.importdatetime AS TIMESTAMP) AS pcn_importdatetime, --147-- try timestamp to timestamp
    TRY_CAST(p.import_year AS VARCHAR) AS pcn_import_year, --148-- try string to string (default)
    TRY_CAST(p.import_month AS VARCHAR) AS pcn_import_month, --149-- try string to string (default)
    TRY_CAST(p.import_day AS VARCHAR) AS pcn_import_day, --150-- try string to string (default)
    TRY_CAST(p.import_date AS VARCHAR) AS pcn_import_date, --151-- try string to string (default)
    
    /* teams columns expanded by above subquery */
    team.*,

    /* Partition columns moved to the end to keep schema alligned */
    l.import_year,
    l.import_month,
    l.import_day,
    l.import_date

FROM liberator l    -- < "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic" 
LEFT JOIN "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full" p
/*
    ON p.import_date = l.import_date    -- joined on import partition 
    Fails when "pcnfoidetails_pcn_foi_full" hasn't produced data for l.import_date yet...
    ...resulting in empty pcn_ columns in the output.
    Airflow's orchestration should avoid this after PCNFOIDetails_PCN_FOI_FULL.sql has been migrated...
    ...but for now we'll just use the following simple workaround...
*/ 
    ON p.import_date IN (
            SELECT MAX(g.import_date) AS import_date
            FROM "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full" g
        ) 
    AND l.ticketserialnumber = p.pcn    -- ticketserialnumber is valid
LEFT JOIN team -- < "parking-raw-zone"."parking_correspondence_performance_teams"
    ON UPPER(team.t_full_name) = UPPER(l.Response_written_by)
;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
