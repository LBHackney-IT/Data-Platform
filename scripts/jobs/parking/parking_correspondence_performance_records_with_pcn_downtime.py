"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_correspondence_performance_records_with_pcn_downtime"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
-->> "dataplatform-prod-liberator-refined-zone"."parking_correspondence_performance_records_with_pcn_downtime"
--< "parking-raw-zone"."parking_correspondence_performance_teams" (data from google spreadsheet)
--< "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic"
--<< "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full"
--< "parking-raw-zone"."parking_officer_downtime" (data from google form)
/*
Correspondence Performance records last 13 months with PCN FOI records
16/06/2022 - Created
21/04/2023 - added teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing
02/10/2023 - modified to union data into one output for Downtime data gathered from Google form https://forms.gle/bB53jAayiZ2Ykwjk6
22/10/2024 - translated into PrestoSQL to move away from Glue
01/11/2024 + Refactored SQL to separate the inward column conversions from onward business logic using CTE subqueries and allow improved fault handling.
           + Downtime's Google Sheets alternate date formats properly handled
28/11/2024 - updated downtime records for t_team details to pull from parking_correspondence_performance_teams instead on leaving blank
12/12/2024 + Integrated the previous downtime update into the refactored version
           + Commented out alternative last 13 month filter that caused unexpectedly higher row count
05/03/2025 - Replaced conditional '' empty string outputs with NULL defaults to be consistent with previous Glue/SparkSQL implementations.
14/04/2025 - Strictly applied column formatting consistent with previous Glue outputs. Fixed faulty arithmetic translation of Glue/SparkSQL to AthenaSQL.
16/04/2025 - Workaround orchestration issue caused by latest "pcnfoidetails_pcn_foi_full" not yet ready
*/
/*Teams data from google spreadsheet load - https://docs.google.com/spreadsheets/d/1zxZXX1_qU9NW93Ug1JUy7aXsnTz45qIj7Zftmi9trbI/edit?usp=sharing*/
WITH
team AS (
    SELECT DISTINCT
        start_date AS t_start_date,
        end_date AS t_end_date,
        team AS t_team,
        team_name AS t_team_name,
        ROLE AS t_role,
        forename AS t_forename,
        surname AS t_surname,
        full_name AS t_full_name,
        qa_doc_created_by AS t_qa_doc_created_by,
        qa_doc_full_name AS t_qa_doc_full_name,
        post_title AS t_post_title,
        notes AS t_notes,
        import_date AS t_import_date --*
    FROM "parking-raw-zone"."parking_correspondence_performance_teams"
    WHERE import_date IN (
            SELECT MAX(g.import_date) AS import_date
            FROM "parking-raw-zone"."parking_correspondence_performance_teams" g
        )
),
liberator_pcn_icdate_received_last13months AS (
    SELECT
        *,
        CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS current_utc_timestamp,
        TRY(CAST(date_received AS TIMESTAMP)) AS date_received_timestamp,    -- pre-filtered by WHERE clause

        IF(whenassigned <> '',      -- contains probable valid timestamp
            TRY(CAST(whenassigned AS TIMESTAMP)),
            CAST(NULL AS TIMESTAMP) -- edge case
        ) AS whenassigned_timestamp,

        IF(Response_generated_at <> '',      -- contains probable valid timestamp
            TRY(CAST(Response_generated_at AS TIMESTAMP)),
            CAST(NULL AS TIMESTAMP) -- edge case
        ) AS  Response_generated_at_timestamp,

        CAST(DATE_DIFF(
                'day',
                TRY(CAST(SUBSTR(date_received, 1, 10) AS DATE)), -- under condition of date_received <>''
                CAST(CURRENT_TIMESTAMP AS DATE)
        ) AS BIGINT) AS days_since_date_received,

        CAST(IF(
            whenassigned <> '',
            DATE_DIFF(
                'day',
                TRY(CAST(SUBSTR(date_received, 1, 10) AS DATE)), -- under condition of date_received <>''
                TRY(CAST(SUBSTR(whenassigned, 1, 10) AS DATE))
            ),
            NULL -- edge case
        ) AS BIGINT) AS days_since_date_recieved_whenassigned,

        CAST(IF(
            whenassigned <> '' AND response_generated_at = '',
            DATE_DIFF(
                'day',
                TRY(CAST(SUBSTR(whenassigned, 1, 10) AS DATE)),
                CAST(CURRENT_TIMESTAMP AS DATE)
            ),
            NULL -- edge case
        ) AS BIGINT) AS days_since_whenassigned,

        CAST(IF(
            whenassigned <> '' AND response_generated_at <> '',
            DATE_DIFF(
                'day',
                TRY(CAST(SUBSTR(whenassigned, 1, 10) AS DATE)),
                TRY(CAST(SUBSTR(response_generated_at, 1, 10) AS DATE))
            ),
            NULL -- edge case
        ) AS BIGINT) AS days_since_whenassigned_response_generated_at,

        CAST(IF(
            response_generated_at <> '',
            DATE_DIFF(
                'day',
                TRY(CAST(SUBSTR(date_received, 1, 10) AS DATE)), -- under condition of date_received <>''
                TRY(CAST(SUBSTR(response_generated_at, 1, 10) AS DATE))
            ),
            NULL -- edge case
        ) AS BIGINT) AS days_since_date_received_response_generated_at--,
    FROM "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic"
    WHERE import_Date IN (
            SELECT MAX(g.import_date) AS import_date
            FROM "dataplatform-prod-liberator-raw-zone"."liberator_pcn_ic" g
        )
    AND LENGTH(ticketserialnumber) = 10 -- ticket filter
    AND date_received <>''  -- is the overriding condition for "13 months from todays date"!
    AND CAST(SUBSTR(date_received, 1, 10) AS DATE) > CAST(CURRENT_TIMESTAMP AS DATE) - INTERVAL '13' MONTH
        -- Last 13 months from todays date
/*      -- This alternative method captures slightly more records...
        DATE_DIFF(
            'month',
            TRY(CAST(SUBSTR(date_received, 1, 10) AS DATE)),
            CAST(CURRENT_TIMESTAMP AS DATE)
        ) <= 13
*/
),
liberator_with_team AS (
    SELECT
        /*Fields for union downtime data*/
        CAST('' AS VARCHAR) AS downtime_timestamp,
        CAST('' AS VARCHAR) AS downtime_email_address,
        CAST('' AS VARCHAR) AS officer_s_first_name,
        CAST('' AS VARCHAR) AS officer_s_last_name,
        CAST('' AS VARCHAR) AS liberator_system_username,
        CAST('' AS VARCHAR) AS liberator_system_id,
        CAST('' AS VARCHAR) AS import_datetime,
        CAST('' AS VARCHAR) AS multiple_downtime_days_flag,
        CAST('' AS VARCHAR) AS response_secs,
        CAST('' AS VARCHAR) AS response_mins,
        CAST('' AS VARCHAR) AS response_hours,
        CAST('' AS VARCHAR) AS response_days_plus_one,
        CAST('' AS VARCHAR) AS downtime_total_non_working_mins_with_lunch,
        CAST('' AS VARCHAR) AS downtime_total_non_working_mins,
        CAST('' AS VARCHAR) AS downtime_total_working_mins_with_lunch,
        CAST('' AS VARCHAR) AS downtime_total_working_mins,
        CAST('' AS VARCHAR) AS downtime_total_working_mins_with_lunch_net,
        CAST('' AS VARCHAR) AS downtime_total_working_mins_net,
        CAST('' AS VARCHAR) AS start_date_time,
        CAST('' AS VARCHAR) AS startdate,
        CAST('' AS VARCHAR) AS start_date_datetime,
        CAST('' AS VARCHAR) AS end_date_time,
        CAST('' AS VARCHAR) AS enddate,
        CAST('' AS VARCHAR) AS end_date_datetime,

        /*Liberator Incoming Correspondence Data*/
        CAST(CASE  -- having already asserted date_received <>''
            WHEN l.whenassigned = '' THEN 'Unassigned'
            WHEN l.whenassigned <> '' AND l.response_generated_at = '' THEN 'Assigned'
            WHEN l.whenassigned <> '' AND l.response_generated_at <> '' THEN 'Responded'
            --ELSE NULL
        END AS VARCHAR) AS response_status,

        CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS VARCHAR) AS Current_time_stamp,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned = ''
            THEN 'INTERVAL '''
                || REGEXP_REPLACE(CAST(l.current_utc_timestamp - l.date_received_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
                || ''' DAY TO SECOND'
            --ELSE NULL
        END AS VARCHAR) AS unassigned_time,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned <> ''
            THEN 'INTERVAL '''
                || REGEXP_REPLACE(CAST(l.whenassigned_timestamp - l.date_received_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
                || ''' DAY TO SECOND'
            --ELSE NULL
        END AS VARCHAR) AS to_assigned_time,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
            THEN 'INTERVAL '''
                || REGEXP_REPLACE(CAST(l.current_utc_timestamp - l.whenassigned_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
                || ''' DAY TO SECOND'
            --ELSE NULL
        END AS VARCHAR) AS assigned_in_progress_time,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at <> ''
            THEN 'INTERVAL '''
                || REGEXP_REPLACE(CAST(l.Response_generated_at_timestamp - l.whenassigned_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
                || ''' DAY TO SECOND'
            --ELSE NULL
        END AS VARCHAR) AS assigned_response_time,

        CAST(CASE -- asserted date_received <>''
            WHEN l.response_generated_at <> ''
            THEN 'INTERVAL '''
                || REGEXP_REPLACE(CAST(l.Response_generated_at_timestamp - l.date_received_timestamp AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
                || ''' DAY TO SECOND'
            --ELSE NULL
        END AS VARCHAR) AS response_time,

        /*unassigned days*/
        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned = ''
            THEN CAST(days_since_date_received AS VARCHAR)
            --ELSE NULL
        END AS VARCHAR) AS unassigned_days,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned = ''
            THEN
                CASE
                    WHEN l.days_since_date_received <= 5 THEN '5 or Less days'
                    WHEN l.days_since_date_received BETWEEN 6 AND 14 THEN '6 to 14 days'
                    WHEN l.days_since_date_received BETWEEN 15 AND 47 THEN '15 to 47 days'
                    WHEN l.days_since_date_received BETWEEN 48 AND 56 THEN '48 to 56 days'
                    WHEN l.days_since_date_received > 56 THEN '56 plus days'
                    --ELSE NULL
                END
            --ELSE NULL
        END AS VARCHAR) AS unassigned_days_group,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned = ''
                AND l.days_since_date_received <= 56
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS unassigned_days_kpiTotFiftySixLess,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned = ''
                AND l.days_since_date_received <= 14
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS unassigned_days_kpiTotFourteenLess,

        /*Days to assign*/
        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned <> ''
            THEN CAST(l.days_since_date_recieved_whenassigned AS VARCHAR)
            --ELSE NULL
        END AS VARCHAR) AS Days_to_assign,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned <> ''
            THEN
                CASE
                    WHEN l.days_since_date_recieved_whenassigned <= 5 THEN '5 or Less days'
                    WHEN l.days_since_date_recieved_whenassigned BETWEEN 6 AND 14 THEN '6 to 14 days'
                    WHEN l.days_since_date_recieved_whenassigned BETWEEN 15 AND 47 THEN '15 to 47 days'
                    WHEN l.days_since_date_recieved_whenassigned BETWEEN 48 AND 56 THEN '48 to 56 days'
                    WHEN l.days_since_date_recieved_whenassigned > 56 THEN '56 plus days'
                    --ELSE NULL
                END
            --ELSE NULL
        END AS VARCHAR) AS Days_to_assign_group,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned <> ''
                AND l.days_since_date_recieved_whenassigned <= 56
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS Days_to_assign_kpiTotFiftySixLess,

        CAST(CASE -- asserted date_received <>''
            WHEN l.whenassigned <> ''
                AND l.days_since_date_recieved_whenassigned <= 14
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS Days_to_assign_kpiTotFourteenLess,

        /*assigned in progress days*/
        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
            THEN CAST(l.days_since_whenassigned AS VARCHAR)
            --ELSE NULL
        END AS VARCHAR) AS assigned_in_progress_days,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
            THEN
                CASE
                    WHEN l.days_since_whenassigned <= 5 THEN '5 or Less days'
                    WHEN l.days_since_whenassigned BETWEEN 6 AND 14 THEN '6 to 14 days'
                    WHEN l.days_since_whenassigned BETWEEN 15 AND 47 THEN '15 to 47 days'
                    WHEN l.days_since_whenassigned BETWEEN 48 AND 56 THEN '48 to 56 days'
                    WHEN l.days_since_whenassigned > 56 THEN '56 plus days'
                    --ELSE NULL
                END
            --ELSE NULL
        END AS VARCHAR) AS assigned_in_progress_days_group,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
                AND l.days_since_whenassigned <= 56
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS assigned_in_progress_days_kpiTotFiftySixLess,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
                AND l.days_since_whenassigned <= 14
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS assigned_in_progress_days_kpiTotFourteenLess,

        /*assigned response days*/
        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
            THEN CAST(l.days_since_whenassigned_response_generated_at AS VARCHAR)
            --ELSE NULL
        END AS VARCHAR) AS assignedResponseDays,

       CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
            THEN
                CASE
                    WHEN l.days_since_whenassigned_response_generated_at <= 5 THEN '5 or Less days'
                    WHEN l.days_since_whenassigned_response_generated_at BETWEEN 6 AND 14 THEN '6 to 14 days'
                    WHEN l.days_since_whenassigned_response_generated_at BETWEEN 15 AND 47 THEN '15 to 47 days'
                    WHEN l.days_since_whenassigned_response_generated_at BETWEEN 48 AND 56 THEN '48 to 56 days'
                    WHEN l.days_since_whenassigned_response_generated_at > 56 THEN '56 plus days'
                    --ELSE NULL
                END
            --ELSE NULL
        END AS VARCHAR) AS assignedResponseDays_group,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at <> ''
                AND l.days_since_whenassigned_response_generated_at <= 56
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS assignedResponseDays_kpiTotFiftySixLess,

        CAST(CASE
            WHEN l.whenassigned <> ''
                AND l.response_generated_at = ''
                AND l.days_since_whenassigned_response_generated_at <= 14
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS assignedResponseDays_kpiTotFourteenLess,

        /*Response days*/
        CAST(CASE -- asserted date_received <>''
            WHEN l.response_generated_at <> ''
            THEN CAST(l.days_since_date_received_response_generated_at AS VARCHAR)
            --ELSE NULL
        END AS VARCHAR) AS ResponseDays,

        CAST(CASE -- asserted date_received <>''
            WHEN l.response_generated_at = ''
            THEN
                CASE
                    WHEN l.days_since_date_received_response_generated_at <= 5 THEN '5 or Less days'
                    WHEN l.days_since_date_received_response_generated_at BETWEEN 6 AND 14 THEN '6 to 14 days'
                    WHEN l.days_since_date_received_response_generated_at BETWEEN 15 AND 47 THEN '15 to 47 days'
                    WHEN l.days_since_date_received_response_generated_at BETWEEN 48 AND 56 THEN '48 to 56 days'
                    WHEN l.days_since_date_received_response_generated_at > 56 THEN '56 plus days'
                    --ELSE NULL
                END
            --ELSE NULL
        END AS VARCHAR) AS ResponseDays_group,

        CAST(CASE -- asserted date_received <>''
            WHEN l.response_generated_at <> ''
                AND l.days_since_date_received_response_generated_at <= 56
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS ResponseDays_kpiTotFiftySixLess,

        CAST(CASE -- asserted date_received <>''
            WHEN l.response_generated_at <> ''
                AND l.days_since_date_received_response_generated_at <= 14
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS ResponseDays_kpiTotFourteenLess,

        Response_generated_at,
        Date_Received,

        SUBSTR(CAST(l.date_received AS VARCHAR (10)), 1, 7) || '-01' AS MonthYear,

        l.Type AS "Type",
        l.Serviceable,
        l.Service_category,
        l.Response_written_by,
        l.Letter_template,
        l.Action_taken,
        l.Related_to_PCN,
        l.Cancellation_group,
        l.Cancellation_reason,
        l.whenassigned,
        l.ticketserialnumber,
        l.noderef,
        CAST(l.record_created AS VARCHAR) AS record_created,

        l.import_timestamp,

        /*pcn data*/
        /*** pcn columns taken from "dataplatform-prod-liberator-refined-zone"."pcnfoidetails_pcn_foi_full" ***/
        -- Data sourced from the refined zone needs to be handled carefully...
        -- Do not assume the following output column datatypes will be the same as "pcnfoidetails_pcn_foi_full".
        -- Being left-joined to "pcnfoidetails_pcn_foi_full" will cause NULLs to appear in these columns.
        -- And similar transforms elsewhere require different translations to the ones below...
        /* These are the current automated translations developed for this transform:-
            TRY_CAST(p.[source_column] AS DATE) AS [target_column], --[position]-- try date to date
            TRY_CAST(p.[source_column] AS VARCHAR) AS [target_column], --[position]-- try int to string
            COALESCE(DATE_FORMAT(TRY_CAST(p.[source_column] AS DATE), '%Y-%m-%d'), CAST(p.[source_column] AS VARCHAR)) AS [target_column], --[position]-- try date to string
            TRY_CAST(p.[source_column] AS INTEGER) AS [target_column], --[position]-- try int to int
            TRY_CAST(p.[source_column] AS VARCHAR) AS [target_column], --[position]-- try string to string (default)
            COALESCE(DATE_FORMAT(TRY_CAST(p.[source_column] AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.[source_column] AS VARCHAR)) AS [target_column], --[position]-- try timestamp to string
            TRY_CAST(p.[source_column] AS TIMESTAMP) AS [target_column], --[position]-- try timestamp to timestamp
        */
        -- These translations try to deal with problems without resorting to throwing errors, tolerating a reasonable degree of schema evolution in the "pcnfoidetails_pcn_foi_full" source.
        -- For example, date and timestamp string formatting works with either string, date and timestamp source columns and works like this...
        /* If source can be cast to a date then it can be correctly date-formatted into a string, otherwise just cast whatever it was to a string.
            COALESCE(
                DATE_FORMAT(TRY_CAST(p.xxxx AS DATE), '%Y-%m-%d'),
                CAST(p.xxxx AS VARCHAR) --...and can be extended to handle other date formats.
            ) AS pcn_xxxx,  -- from DATE
        */
        /* If source can be cast to a timestamp then it can be correctly timestamp-formatted into a string, otherwise just cast whatever it was to a string.
            COALESCE(
                DATE_FORMAT(TRY_CAST(p.xxxx AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'),
                CAST(p.xxxx AS VARCHAR) -- Alternative for transforming a time-zoned timestamp...
                --...COALESCE(DATE_FORMAT(TRY_CAST(TRY(From_iso8601_timestamp(p.xxxx)) AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.xxxx AS VARCHAR))
                --...and can be extended to handle other timestamp formats.
            ) AS pcn_xxxx,  -- from TIMESTAMP
        */
        TRY_CAST(p.pcn AS VARCHAR) AS pcn_pcn, --69-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcnissuedate AS DATE), '%Y-%m-%d'), CAST(p.pcnissuedate AS VARCHAR)) AS pcn_pcnissuedate, --70-- try date to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcnissuedatetime AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcnissuedatetime AS VARCHAR)) AS pcn_pcnissuedatetime, --71-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_canx_date AS DATE), '%Y-%m-%d'), CAST(p.pcn_canx_date AS VARCHAR)) AS pcn_pcn_canx_date, --72-- try date to string
        TRY_CAST(p.cancellationgroup AS VARCHAR) AS pcn_cancellationgroup, --73-- try string to string (default)
        TRY_CAST(p.cancellationreason AS VARCHAR) AS pcn_cancellationreason, --74-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_casecloseddate AS DATE), '%Y-%m-%d'), CAST(p.pcn_casecloseddate AS VARCHAR)) AS pcn_pcn_casecloseddate, --75-- try date to string
        TRY_CAST(p.street_location AS VARCHAR) AS pcn_street_location, --76-- try string to string (default)
        TRY_CAST(p.whereonlocation AS VARCHAR) AS pcn_whereonlocation, --77-- try string to string (default)
        TRY_CAST(p.zone AS VARCHAR) AS pcn_zone, --78-- try string to string (default)
        TRY_CAST(p.usrn AS VARCHAR) AS pcn_usrn, --79-- try string to string (default)
        TRY_CAST(p.contraventioncode AS VARCHAR) AS pcn_contraventioncode, --80-- try string to string (default)
        TRY_CAST(p.contraventionsuffix AS VARCHAR) AS pcn_contraventionsuffix, --81-- try string to string (default)
        TRY_CAST(p.debttype AS VARCHAR) AS pcn_debttype, --82-- try string to string (default)
        TRY_CAST(p.vrm AS VARCHAR) AS pcn_vrm, --83-- try string to string (default)
        TRY_CAST(p.vehiclemake AS VARCHAR) AS pcn_vehiclemake, --84-- try string to string (default)
        TRY_CAST(p.vehiclemodel AS VARCHAR) AS pcn_vehiclemodel, --85-- try string to string (default)
        TRY_CAST(p.vehiclecolour AS VARCHAR) AS pcn_vehiclecolour, --86-- try string to string (default)
        TRY_CAST(p.ceo AS VARCHAR) AS pcn_ceo, --87-- try string to string (default)
        TRY_CAST(p.ceodevice AS VARCHAR) AS pcn_ceodevice, --88-- try string to string (default)
        TRY_CAST(p.current_30_day_flag AS VARCHAR) AS pcn_current_30_day_flag, --89-- try int to string
        TRY_CAST(p.isvda AS VARCHAR) AS pcn_isvda, --90-- try int to string
        TRY_CAST(p.isvoid AS VARCHAR) AS pcn_isvoid, --91-- try int to string
        TRY_CAST(p.isremoval AS VARCHAR) AS pcn_isremoval, --92-- try string to string (default)
        TRY_CAST(p.driverseen AS VARCHAR) AS pcn_driverseen, --93-- try string to string (default)
        TRY_CAST(p.allwindows AS VARCHAR) AS pcn_allwindows, --94-- try string to string (default)
        TRY_CAST(p.parkedonfootway AS VARCHAR) AS pcn_parkedonfootway, --95-- try string to string (default)
        TRY_CAST(p.doctor AS VARCHAR) AS pcn_doctor, --96-- try string to string (default)
        TRY_CAST(p.warningflag AS VARCHAR) AS pcn_warningflag, --97-- try int to string
        TRY_CAST(p.progressionstage AS VARCHAR) AS pcn_progressionstage, --98-- try string to string (default)
        TRY_CAST(p.nextprogressionstage AS VARCHAR) AS pcn_nextprogressionstage, --99-- try string to string (default)
        TRY_CAST(p.nextprogressionstagestarts AS VARCHAR) AS pcn_nextprogressionstagestarts, --100-- try string to string (default)
        TRY_CAST(p.holdreason AS VARCHAR) AS pcn_holdreason, --101-- try string to string (default)
        TRY_CAST(p.lib_initial_debt_amount AS VARCHAR) AS pcn_lib_initial_debt_amount, --102-- try string to string (default)
        TRY_CAST(p.lib_payment_received AS VARCHAR) AS pcn_lib_payment_received, --103-- try string to string (default)
        TRY_CAST(p.lib_write_off_amount AS VARCHAR) AS pcn_lib_write_off_amount, --104-- try string to string (default)
        TRY_CAST(p.lib_payment_void AS VARCHAR) AS pcn_lib_payment_void, --105-- try string to string (default)
        TRY_CAST(p.lib_payment_method AS VARCHAR) AS pcn_lib_payment_method, --106-- try string to string (default)
        TRY_CAST(p.lib_payment_ref AS VARCHAR) AS pcn_lib_payment_ref, --107-- try string to string (default)
        TRY_CAST(p.baliff_from AS VARCHAR) AS pcn_baliff_from, --108-- try string to string (default)
        TRY_CAST(p.bailiff_to AS VARCHAR) AS pcn_bailiff_to, --109-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.bailiff_processedon AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.bailiff_processedon AS VARCHAR)) AS pcn_bailiff_processedon, --110-- try timestamp to string
        TRY_CAST(p.bailiff_redistributionreason AS VARCHAR) AS pcn_bailiff_redistributionreason, --111-- try string to string (default)
        TRY_CAST(p.bailiff AS VARCHAR) AS pcn_bailiff, --112-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.warrantissuedate AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.warrantissuedate AS VARCHAR)) AS pcn_warrantissuedate, --113-- try timestamp to string
        TRY_CAST(p.allocation AS VARCHAR) AS pcn_allocation, --114-- try int to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.eta_datenotified AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.eta_datenotified AS VARCHAR)) AS pcn_eta_datenotified, --115-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.eta_packsubmittedon AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.eta_packsubmittedon AS VARCHAR)) AS pcn_eta_packsubmittedon, --116-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.eta_evidencedate AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.eta_evidencedate AS VARCHAR)) AS pcn_eta_evidencedate, --117-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.eta_adjudicationdate AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.eta_adjudicationdate AS VARCHAR)) AS pcn_eta_adjudicationdate, --118-- try timestamp to string
        TRY_CAST(p.eta_appealgrounds AS VARCHAR) AS pcn_eta_appealgrounds, --119-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.eta_decisionreceived AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.eta_decisionreceived AS VARCHAR)) AS pcn_eta_decisionreceived, --120-- try timestamp to string
        TRY_CAST(p.eta_outcome AS VARCHAR) AS pcn_eta_outcome, --121-- try string to string (default)
        TRY_CAST(p.eta_packsubmittedby AS VARCHAR) AS pcn_eta_packsubmittedby, --122-- try string to string (default)
        TRY_CAST(p.cancelledby AS VARCHAR) AS pcn_cancelledby, --123-- try string to string (default)
        TRY_CAST(p.registered_keeper_address AS VARCHAR) AS pcn_registered_keeper_address, --124-- try string to string (default)
        TRY_CAST(p.current_ticket_address AS VARCHAR) AS pcn_current_ticket_address, --125-- try string to string (default)
        TRY_CAST(p.corresp_dispute_flag AS VARCHAR) AS pcn_corresp_dispute_flag, --126-- try int to string
        TRY_CAST(p.keyworker_corresp_dispute_flag AS VARCHAR) AS pcn_keyworker_corresp_dispute_flag, --127-- try int to string
        TRY_CAST(p.fin_year_flag AS VARCHAR) AS pcn_fin_year_flag, --128-- try string to string (default)
        TRY_CAST(p.fin_year AS VARCHAR) AS pcn_fin_year, --129-- try string to string (default)
        TRY_CAST(p.ticket_ref AS VARCHAR) AS pcn_ticket_ref, --130-- try string to string (default)
        COALESCE(DATE_FORMAT(TRY_CAST(p.nto_printed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.nto_printed AS VARCHAR)) AS pcn_nto_printed, --131-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.appeal_accepted AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.appeal_accepted AS VARCHAR)) AS pcn_appeal_accepted, --132-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.arrived_in_pound AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.arrived_in_pound AS VARCHAR)) AS pcn_arrived_in_pound, --133-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.cancellation_reversed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.cancellation_reversed AS VARCHAR)) AS pcn_cancellation_reversed, --134-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.cc_printed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.cc_printed AS VARCHAR)) AS pcn_cc_printed, --135-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.drr AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.drr AS VARCHAR)) AS pcn_drr, --136-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.en_printed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.en_printed AS VARCHAR)) AS pcn_en_printed, --137-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.hold_released AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.hold_released AS VARCHAR)) AS pcn_hold_released, --138-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.dvla_response AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.dvla_response AS VARCHAR)) AS pcn_dvla_response, --139-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.dvla_request AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.dvla_request AS VARCHAR)) AS pcn_dvla_request, --140-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.full_rate_uplift AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.full_rate_uplift AS VARCHAR)) AS pcn_full_rate_uplift, --141-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.hold_until AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.hold_until AS VARCHAR)) AS pcn_hold_until, --142-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.lifted_at AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.lifted_at AS VARCHAR)) AS pcn_lifted_at, --143-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.lifted_by AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.lifted_by AS VARCHAR)) AS pcn_lifted_by, --144-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.loaded AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.loaded AS VARCHAR)) AS pcn_loaded, --145-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.nor_sent AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.nor_sent AS VARCHAR)) AS pcn_nor_sent, --146-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.notice_held AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.notice_held AS VARCHAR)) AS pcn_notice_held, --147-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.ofr_printed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.ofr_printed AS VARCHAR)) AS pcn_ofr_printed, --148-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_printed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_printed AS VARCHAR)) AS pcn_pcn_printed, --149-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.reissue_nto_requested AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.reissue_nto_requested AS VARCHAR)) AS pcn_reissue_nto_requested, --150-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.reissue_pcn AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.reissue_pcn AS VARCHAR)) AS pcn_reissue_pcn, --151-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.set_back_to_pre_cc_stage AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.set_back_to_pre_cc_stage AS VARCHAR)) AS pcn_set_back_to_pre_cc_stage, --152-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.vehicle_released_for_auction AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.vehicle_released_for_auction AS VARCHAR)) AS pcn_vehicle_released_for_auction, --153-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.warrant_issued AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.warrant_issued AS VARCHAR)) AS pcn_warrant_issued, --154-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.warrant_redistributed AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.warrant_redistributed AS VARCHAR)) AS pcn_warrant_redistributed, --155-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.warrant_request_granted AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.warrant_request_granted AS VARCHAR)) AS pcn_warrant_request_granted, --156-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.ad_hoc_vq4_request AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.ad_hoc_vq4_request AS VARCHAR)) AS pcn_ad_hoc_vq4_request, --157-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.paper_vq5_received AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.paper_vq5_received AS VARCHAR)) AS pcn_paper_vq5_received, --158-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_buslane AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_buslane AS VARCHAR)) AS pcn_pcn_extracted_for_buslane, --159-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_pre_debt AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_pre_debt AS VARCHAR)) AS pcn_pcn_extracted_for_pre_debt, --160-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_collection AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_collection AS VARCHAR)) AS pcn_pcn_extracted_for_collection, --161-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_drr AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_drr AS VARCHAR)) AS pcn_pcn_extracted_for_drr, --162-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_cc AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_cc AS VARCHAR)) AS pcn_pcn_extracted_for_cc, --163-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_nto AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_nto AS VARCHAR)) AS pcn_pcn_extracted_for_nto, --164-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_print AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_print AS VARCHAR)) AS pcn_pcn_extracted_for_print, --165-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.warning_notice_extracted_for_print AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.warning_notice_extracted_for_print AS VARCHAR)) AS pcn_warning_notice_extracted_for_print, --166-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_ofr AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_ofr AS VARCHAR)) AS pcn_pcn_extracted_for_ofr, --167-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pcn_extracted_for_warrant_request AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pcn_extracted_for_warrant_request AS VARCHAR)) AS pcn_pcn_extracted_for_warrant_request, --168-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.pre_debt_new_debtor_details AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.pre_debt_new_debtor_details AS VARCHAR)) AS pcn_pre_debt_new_debtor_details, --169-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.importdattime AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.importdattime AS VARCHAR)) AS pcn_importdattime, --170-- try timestamp to string
        COALESCE(DATE_FORMAT(TRY_CAST(p.importdatetime AS TIMESTAMP), '%Y-%m-%d %H:%i:%s'), CAST(p.importdatetime AS VARCHAR)) AS pcn_importdatetime, --171-- try timestamp to string
        TRY_CAST(p.import_year AS VARCHAR) AS pcn_import_year, --172-- try string to string (default)
        TRY_CAST(p.import_month AS VARCHAR) AS pcn_import_month, --173-- try string to string (default)
        TRY_CAST(p.import_day AS VARCHAR) AS pcn_import_day, --174-- try string to string (default)
        TRY_CAST(p.import_date AS VARCHAR) AS pcn_import_date, --175-- try string to string (default)

        /* teams */
        t.t_start_date,
        t.t_end_date,
        t.t_team,
        t.t_team_name,
        t.t_role,
        t.t_forename,
        t.t_surname,
        t.t_full_name,
        t.t_qa_doc_created_by,
        t.t_qa_doc_full_name,
        t.t_post_title,
        t.t_notes,
        t.t_import_date,

        /* Partition columns moved to the end to keep schema alligned */
        l.import_year,
        l.import_month,
        l.import_day,
        l.import_date

    FROM liberator_pcn_icdate_received_last13months l
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
    LEFT JOIN team t
        ON UPPER(t.t_full_name) = UPPER(l.Response_written_by)
),

downtime_start_date_end_date_last13months AS (
    SELECT *,

        IF(start_date LIKE '%/%/%',      -- contains possible valid timestamp
            TRY(PARSE_DATETIME(start_date, 'dd/MM/yyyy HH:mm:ss')),      --> TIMESTAMP with time zone
            IF(start_date LIKE '%-%-%',      -- contains other possible valid timestamp
                TRY(PARSE_DATETIME(start_date, 'yyyy-MM-dd HH:mm:ss')),      --> TIMESTAMP with time zone
                CAST(NULL AS TIMESTAMP) -- edge case
            )
        ) AS start_timestampZ,

        IF(end_date LIKE '%/%/%',      -- contains possible valid timestamp
            TRY(PARSE_DATETIME(end_date, 'dd/MM/yyyy HH:mm:ss')),      --> TIMESTAMP with time zone
            IF(end_date LIKE '%-%-%',      -- contains other possible valid timestamp
                TRY(PARSE_DATETIME(end_date, 'yyyy-MM-dd HH:mm:ss')),      --> TIMESTAMP with time zone
                CAST(NULL AS TIMESTAMP) -- edge case
            )
        ) AS end_timestampZ--,

    FROM "parking-raw-zone"."parking_officer_downtime"
    WHERE import_date IN (
            SELECT MAX(g.import_date) AS import_date
            FROM "parking-raw-zone"."parking_officer_downtime" g
        )
    AND "timestamp" NOT LIKE ''
    AND "timestamp" NOT LIKE '#REF!'
    AND CAST(SUBSTR(CAST("timestamp" as VARCHAR(30)), 1, 10) AS DATE) > CAST(CURRENT_TIMESTAMP AS DATE) - INTERVAL '13' MONTH
        -- Last 13 months from todays date
/*      -- This alternative method captures slightly more records...
        DATE_DIFF(
            'month',
            TRY(CAST(SUBSTR("timestamp", 1, 10) AS DATE)),
            CAST(CURRENT_TIMESTAMP AS DATE)
        ) <= 13
*/
),

downtime AS (
    SELECT *,
        /*
        TO_UNIXTIME(PARSE_DATETIME(start_date, 'dd/MM/yyyy HH:mm:ss')) AS start_end_unixtime_seconds,
        TO_UNIXTIME(PARSE_DATETIME(end_date, 'dd/MM/yyyy HH:mm:ss')) AS end_unixtime_seconds,

        TO_UNIXTIME(PARSE_DATETIME(end_date, 'dd/MM/yyyy HH:mm:ss'))
        - TO_UNIXTIME(PARSE_DATETIME(start_date, 'dd/MM/yyyy HH:mm:ss')) AS downtime_secs,

        -- downtime_secs / 60 AS downtime_mins
        -- downtime_secs / 3600 AS downtime_hours
        */

        DATE_DIFF(
            'second',
            start_timestampZ,
            end_timestampZ
        ) AS downtime_secs,

        DATE_DIFF(
            'minute',
            start_timestampZ,
            end_timestampZ
        ) AS downtime_mins,

        DATE_DIFF(
            'hour',
            start_timestampZ,
            end_timestampZ
        ) AS downtime_hours,

        DATE_DIFF(
            'day',
            start_timestampZ,
            end_timestampZ
        ) AS downtime_days,

        TRIM(officer_s_first_name) || ' ' || TRIM(officer_s_last_name) AS Response_written_by --downtime officer full name

    FROM downtime_start_date_end_date_last13months
),

google_form AS (
    --Downtime data gathered from Google form https://forms.gle/bB53jAayiZ2Ykwjk6
    SELECT
        CAST(d."timestamp" AS VARCHAR) AS downtime_timestamp,
        d.email_address AS downtime_email_address,
        TRIM(d.officer_s_first_name) AS officer_s_first_name,
        TRIM(d.officer_s_last_name) AS officer_s_last_name,
        d.liberator_system_username,
        d.liberator_system_id,
        CAST(d.import_datetime AS VARCHAR) AS import_datetime,

        /* Throughout asserts...
            "timestamp" NOT LIKE ''
            AND "timestamp" NOT LIKE '#REF!'
        */
        CAST(CASE
            WHEN d.downtime_mins > 1440 /* downtime mins (response_mins) */
            THEN '1'
            ELSE '0'
        END AS VARCHAR) AS multiple_downtime_days_flag,

        -- Because the Glue job's response_secs string output was cast from a bigint returned from unix_timestamp...
        -- ...there was no need to cast it to a DOUBLE here...
        CAST(d.downtime_secs AS VARCHAR) AS response_secs,
        -- ...unlike the products below where SparkSQL and AthenaSQL differed in their arithmetic outcomes...

        /* This version was rejected because the output differs wildly from the original Glue output...
        -- Here all input value was cast beforehand to DOUBLE.
        CAST(CAST(d.downtime_secs AS DOUBLE)/60 AS VARCHAR) AS REJECTED_response_mins,
        */
        -- So we are keeping this version because it produces closest to the original Glue output...
        -- Though beware, the final cast to DOUBLE causes a misleading .0 to be formatted in the VARCHAR output...
        CAST(CAST(d.downtime_mins AS DOUBLE) AS VARCHAR) AS response_mins,
        /* But might the following version be the better solution?
        -- This does not add the misleading .0 output in the previous version because it is an integer calculation from start to finish...
        CAST(d.downtime_mins AS VARCHAR) AS ALTERNATIVE_response_mins,
        */

        -- We are keeping this version because it produces closest to the original Glue output...
        -- Though beware, several decimal places may be produced in the VARCHAR output...
        CAST(CAST(d.downtime_secs AS DOUBLE)/3600 AS VARCHAR) AS response_hours,
        /* But might the following version be the better solution?
        -- This does not produce the fractional mantissa because it is an integer calculation from start to finish...
        CAST(d.downtime_hours AS VARCHAR) AS ALTERNATIVE_response_hours,
        */

        /*Downtime calendar days*/
        -- Warning: A small number outlier cases, producing negative values in original Glue output are also produced here...
        CAST(d.downtime_days + 1 AS VARCHAR) AS response_days_plus_one, -- downtime days plus one calendar day

        /*Downtime non working mins*/
        CAST(CASE
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1 ) * 948    /*response_days_plus_one*/
            WHEN d.downtime_mins <= 1440 THEN 948
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS downtime_total_non_working_mins_with_lunch, --if greater than 1440 mins then (days + 1) * 948  "

        CAST(CASE /* downtime mins (response_mins)*/
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 1008 /*response_days_plus_one*/
            WHEN d.downtime_mins <= 1440 THEN 1008
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS downtime_total_non_working_mins, --if greater than 1440 mins then (days + 1) * 1008 "

        /*Downtime working mins*/
        CAST(CASE /* downtime mins (response_mins)*/
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 492 /*response_days_plus_one*/
            WHEN d.downtime_mins <= 1440 THEN 492
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS downtime_total_working_mins_with_lunch, -- 492 mins = 8hrs 12 mins working day including lunch"

        CAST(CASE /* downtime mins (response_mins)*/
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 432 /*response_days_plus_one*/
            WHEN d.downtime_mins <= 1440 THEN 432
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS downtime_total_working_mins, -- 432 mins = 7hrs 12mins working hours"

        /* Downtime working mins net (less downtime mins)*/

        /* This version was rejected because the output differs wildly from the original Glue output...
        -- Here all input values were cast beforehand to DOUBLE...
        CAST(CASE   -- downtime mins (response_mins)
            WHEN CAST(d.downtime_secs AS DOUBLE)/60 > 1440 THEN (CAST(d.downtime_secs AS DOUBLE)/86400 + 1) * 492  -- response_days_plus_one
            WHEN CAST(d.downtime_secs AS DOUBLE)/60 <= 1440 THEN 492 - CAST(d.downtime_secs AS DOUBLE)/60
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS REJECTED_downtime_total_working_mins_with_lunch_net, -- 492 mins = 8hrs 12 mins "working day including lunch less downtime"
        */
        -- So we are keeping this version because it produces closest to the original Glue output...
        -- Though beware, the final cast to DOUBLE causes a misleading .0 to be formatted in the VARCHAR output...
        CAST(CAST(CASE  -- downtime mins (response_mins)
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 492
            WHEN d.downtime_mins <= 1440 THEN 492 - d.downtime_mins
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS DOUBLE) AS VARCHAR) AS downtime_total_working_mins_with_lunch_net, -- 492 mins = 8hrs 12 mins "working day including lunch less downtime"
        /* So might the following version be the better solution?
        -- This does not add the misleading .0 output in the previous version because it is an integer calculation from start to finish...
        CAST(CASE -- downtime mins (response_mins)
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 492
            WHEN d.downtime_mins <= 1440 THEN 492 - d.downtime_mins
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS ALTERNATIVE_downtime_total_working_mins_with_lunch_net, -- 492 mins = 8hrs 12 mins "working day including lunch less downtime"
        */

        /* This version was rejected because the output differs wildly from the original Glue output...
        -- Here all input values were cast beforehand to DOUBLE...
        CAST(CASE -- downtime mins (response_mins)
            WHEN CAST(d.downtime_secs AS DOUBLE)/60 > 1440 THEN (CAST(d.downtime_secs AS DOUBLE)/86400 + 1) * 432 -- response_days_plus_one
            WHEN CAST(d.downtime_secs AS DOUBLE)/60 <= 1440 THEN 432 - CAST(d.downtime_secs AS DOUBLE)/60
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS REJECTED_downtime_total_working_mins_net, -- 432 mins = 7hrs 12mins "working hours"
        */
        -- So we are keeping this version because it produces closest to the original Glue output...
        -- Though beware, the final cast to DOUBLE causes a misleading .0 to be formatted in the VARCHAR output...
        CAST(CAST(CASE -- downtime mins (response_mins)
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 432 -- response_days_plus_one
            WHEN d.downtime_mins <= 1440 THEN 432 - d.downtime_mins
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS DOUBLE) AS VARCHAR) AS downtime_total_working_mins_net, -- 432 mins = 7hrs 12mins "working hours"
        /* So might the following version be the better solution?
        -- This does not add the misleading .0 output in the previous version because it is an integer calculation from start to finish...
        CAST(CASE -- downtime mins (response_mins)
            WHEN d.downtime_mins > 1440 THEN (d.downtime_days + 1) * 432 -- response_days_plus_one
            WHEN d.downtime_mins <= 1440 THEN 432 - d.downtime_mins
            --ELSE NULL --edge case NULL VARCHAR will be materialized in denormalized target table
        END AS VARCHAR) AS ALTERNATIVE_downtime_total_working_mins_net, -- 432 mins = 7hrs 12mins "working hours"
        */

        CAST(SUBSTR(CAST(d.start_date AS VARCHAR), 12, 5) AS VARCHAR) AS start_date_time,
        CAST(SUBSTR(CAST(d.start_date AS VARCHAR), 1, 10) AS VARCHAR) AS startdate,

        CAST(SUBSTR(
            CAST(d.start_timestampZ AS VARCHAR(30)),
            1,
            16
        ) AS VARCHAR) AS start_date_datetime,

        CAST(SUBSTR(CAST(d.end_date AS VARCHAR), 12, 5) AS VARCHAR) AS end_date_time,
        CAST(SUBSTR(CAST(d.end_date AS VARCHAR), 1, 10) AS VARCHAR) AS enddate,

        CAST(SUBSTR(
            CAST(d.end_timestampZ AS VARCHAR(30)),
            1,
            16
        ) AS VARCHAR) AS end_date_datetime,

        CAST('Downtime' AS VARCHAR) AS response_status,
        CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS VARCHAR) AS Current_time_stamp,

        /*Liberator Incoming Correspondence Data*/
        CAST('' AS VARCHAR) AS unassigned_time,
        CAST('' AS VARCHAR) AS to_assigned_time,
        CAST('' AS VARCHAR) AS assigned_in_progress_time,
        CAST('' AS VARCHAR) AS assigned_response_time,

        -- Is there a better way to do this? Substring captures only the minutes...
        'INTERVAL '''
            || REGEXP_REPLACE(CAST(
                    TRY(CAST(SUBSTR(
                        CAST(d.end_timestampZ AS VARCHAR(30)),
                        1,
                        16
                    ) AS TIMESTAMP))
                    - TRY(CAST(SUBSTR(
                        CAST(d.start_timestampZ AS VARCHAR(30)),
                        1,
                        16
                    ) AS TIMESTAMP))
                AS VARCHAR), '(\.\d+)\s*$', '') --removes mantissa
            || ''' DAY TO SECOND'
            AS response_time, --as downtime_duration  --line 30


        CAST('' AS VARCHAR) AS unassigned_days,
        CAST('' AS VARCHAR) AS unassigned_days_group,
        CAST('' AS VARCHAR) AS unassigned_days_kpiTotFiftySixLess,
        CAST('' AS VARCHAR) AS unassigned_days_kpiTotFourteenLess,
        CAST('' AS VARCHAR) AS Days_to_assign,
        CAST('' AS VARCHAR) AS Days_to_assign_group,
        CAST('' AS VARCHAR) AS Days_to_assign_kpiTotFiftySixLess,
        CAST('' AS VARCHAR) AS Days_to_assign_kpiTotFourteenLess,
        CAST('' AS VARCHAR) AS assigned_in_progress_days,
        CAST('' AS VARCHAR) AS assigned_in_progress_days_group,
        CAST('' AS VARCHAR) AS assigned_in_progress_days_kpiTotFiftySixLess,
        CAST('' AS VARCHAR) AS assigned_in_progress_days_kpiTotFourteenLess,
        CAST('' AS VARCHAR) AS assignedResponseDays,
        CAST('' AS VARCHAR) AS assignedResponseDays_group,
        CAST('' AS VARCHAR) AS assignedResponseDays_kpiTotFiftySixLess,
        CAST('' AS VARCHAR) AS assignedResponseDays_kpiTotFourteenLess,

        CAST(DATE_DIFF(
            'day',
            CAST(SUBSTR(
                CAST(d.start_timestampZ AS VARCHAR(30)),
                1,
                10
            ) AS DATE),
            CAST(SUBSTR(
                CAST(d.end_timestampZ AS VARCHAR(30)),
                1,
                10
            ) AS DATE)
        ) AS VARCHAR) AS ResponseDays, --as downtime_duration in days

        CAST('' AS VARCHAR) AS ResponseDays_group,
        CAST('' AS VARCHAR) AS ResponseDays_kpiTotFiftySixLess,
        CAST('' AS VARCHAR) AS ResponseDays_kpiTotFourteenLess,

        d.end_date AS Response_generated_at,
        d.start_date AS Date_Received,

        SUBSTR(
            CAST(d.end_timestampZ AS VARCHAR(30)),
            1,
            7
        ) || '-01' AS MonthYear,

        'Downtime' AS "Type",

        d.downtime AS Serviceable, -- downtime --,'Downtime' as Serviceable -- downtime

        CAST('' AS VARCHAR) AS Service_category,

        d.Response_written_by, --downtime officer full name

        CAST('' AS VARCHAR) AS Letter_template,
        CAST('' AS VARCHAR) AS Action_taken,
        CAST('' AS VARCHAR) AS Related_to_PCN,
        CAST('' AS VARCHAR) AS Cancellation_group,
        CAST('' AS VARCHAR) AS Cancellation_reason,
        CAST('' AS VARCHAR) AS whenassigned,
        CAST('' AS VARCHAR) AS ticketserialnumber,
        CAST('' AS VARCHAR) AS noderef,
        CAST('' AS VARCHAR) AS record_created,
        d.import_timestamp,

        /*pcn data*/
        -- The original Glue SparkSQL had all of these pcn columns output as '' empty strings which either...
        -- ...conflicted with the output column datatypes configured by Glue
        -- ...and/or conflicted with the column translations done earlier in the SQL script.
        /* Instead here, the null or empty translations are deliberately set to depend on the target datatype...
            CAST(NULL AS DATE) AS [target_column], --[position]-- null date
            CAST(NULL AS VARCHAR) AS [target_column], --[position]-- null string
            CAST(NULL AS VARCHAR) AS [target_column], --[position]-- null string
            CAST(NULL AS INTEGER) AS [target_column], --[position]-- null int
            CAST('' AS VARCHAR) AS [target_column], --[position]-- empty string
            CAST(NULL AS VARCHAR) AS [target_column], --[position]-- null string
            CAST(NULL AS TIMESTAMP) AS [target_column], --[position]-- null timestamp
        */
        CAST('' AS VARCHAR) AS pcn_pcn, --69-- empty string
        CAST(NULL AS VARCHAR) AS pcn_pcnissuedate, --70-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcnissuedatetime, --71-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_canx_date, --72-- null string
        CAST('' AS VARCHAR) AS pcn_cancellationgroup, --73-- empty string
        CAST('' AS VARCHAR) AS pcn_cancellationreason, --74-- empty string
        CAST(NULL AS VARCHAR) AS pcn_pcn_casecloseddate, --75-- null string
        CAST('' AS VARCHAR) AS pcn_street_location, --76-- empty string
        CAST('' AS VARCHAR) AS pcn_whereonlocation, --77-- empty string
        CAST('' AS VARCHAR) AS pcn_zone, --78-- empty string
        CAST('' AS VARCHAR) AS pcn_usrn, --79-- empty string
        CAST('' AS VARCHAR) AS pcn_contraventioncode, --80-- empty string
        CAST('' AS VARCHAR) AS pcn_contraventionsuffix, --81-- empty string
        CAST('' AS VARCHAR) AS pcn_debttype, --82-- empty string
        CAST('' AS VARCHAR) AS pcn_vrm, --83-- empty string
        CAST('' AS VARCHAR) AS pcn_vehiclemake, --84-- empty string
        CAST('' AS VARCHAR) AS pcn_vehiclemodel, --85-- empty string
        CAST('' AS VARCHAR) AS pcn_vehiclecolour, --86-- empty string
        CAST('' AS VARCHAR) AS pcn_ceo, --87-- empty string
        CAST('' AS VARCHAR) AS pcn_ceodevice, --88-- empty string
        CAST(NULL AS VARCHAR) AS pcn_current_30_day_flag, --89-- null string
        CAST(NULL AS VARCHAR) AS pcn_isvda, --90-- null string
        CAST(NULL AS VARCHAR) AS pcn_isvoid, --91-- null string
        CAST('' AS VARCHAR) AS pcn_isremoval, --92-- empty string
        CAST('' AS VARCHAR) AS pcn_driverseen, --93-- empty string
        CAST('' AS VARCHAR) AS pcn_allwindows, --94-- empty string
        CAST('' AS VARCHAR) AS pcn_parkedonfootway, --95-- empty string
        CAST('' AS VARCHAR) AS pcn_doctor, --96-- empty string
        CAST(NULL AS VARCHAR) AS pcn_warningflag, --97-- null string
        CAST('' AS VARCHAR) AS pcn_progressionstage, --98-- empty string
        CAST('' AS VARCHAR) AS pcn_nextprogressionstage, --99-- empty string
        CAST('' AS VARCHAR) AS pcn_nextprogressionstagestarts, --100-- empty string
        CAST('' AS VARCHAR) AS pcn_holdreason, --101-- empty string
        CAST('' AS VARCHAR) AS pcn_lib_initial_debt_amount, --102-- empty string
        CAST('' AS VARCHAR) AS pcn_lib_payment_received, --103-- empty string
        CAST('' AS VARCHAR) AS pcn_lib_write_off_amount, --104-- empty string
        CAST('' AS VARCHAR) AS pcn_lib_payment_void, --105-- empty string
        CAST('' AS VARCHAR) AS pcn_lib_payment_method, --106-- empty string
        CAST('' AS VARCHAR) AS pcn_lib_payment_ref, --107-- empty string
        CAST('' AS VARCHAR) AS pcn_baliff_from, --108-- empty string
        CAST('' AS VARCHAR) AS pcn_bailiff_to, --109-- empty string
        CAST(NULL AS VARCHAR) AS pcn_bailiff_processedon, --110-- null string
        CAST('' AS VARCHAR) AS pcn_bailiff_redistributionreason, --111-- empty string
        CAST('' AS VARCHAR) AS pcn_bailiff, --112-- empty string
        CAST(NULL AS VARCHAR) AS pcn_warrantissuedate, --113-- null string
        CAST(NULL AS VARCHAR) AS pcn_allocation, --114-- null string
        CAST(NULL AS VARCHAR) AS pcn_eta_datenotified, --115-- null string
        CAST(NULL AS VARCHAR) AS pcn_eta_packsubmittedon, --116-- null string
        CAST(NULL AS VARCHAR) AS pcn_eta_evidencedate, --117-- null string
        CAST(NULL AS VARCHAR) AS pcn_eta_adjudicationdate, --118-- null string
        CAST('' AS VARCHAR) AS pcn_eta_appealgrounds, --119-- empty string
        CAST(NULL AS VARCHAR) AS pcn_eta_decisionreceived, --120-- null string
        CAST('' AS VARCHAR) AS pcn_eta_outcome, --121-- empty string
        CAST('' AS VARCHAR) AS pcn_eta_packsubmittedby, --122-- empty string
        CAST('' AS VARCHAR) AS pcn_cancelledby, --123-- empty string
        CAST('' AS VARCHAR) AS pcn_registered_keeper_address, --124-- empty string
        CAST('' AS VARCHAR) AS pcn_current_ticket_address, --125-- empty string
        CAST(NULL AS VARCHAR) AS pcn_corresp_dispute_flag, --126-- null string
        CAST(NULL AS VARCHAR) AS pcn_keyworker_corresp_dispute_flag, --127-- null string
        CAST('' AS VARCHAR) AS pcn_fin_year_flag, --128-- empty string
        CAST('' AS VARCHAR) AS pcn_fin_year, --129-- empty string
        CAST('' AS VARCHAR) AS pcn_ticket_ref, --130-- empty string
        CAST(NULL AS VARCHAR) AS pcn_nto_printed, --131-- null string
        CAST(NULL AS VARCHAR) AS pcn_appeal_accepted, --132-- null string
        CAST(NULL AS VARCHAR) AS pcn_arrived_in_pound, --133-- null string
        CAST(NULL AS VARCHAR) AS pcn_cancellation_reversed, --134-- null string
        CAST(NULL AS VARCHAR) AS pcn_cc_printed, --135-- null string
        CAST(NULL AS VARCHAR) AS pcn_drr, --136-- null string
        CAST(NULL AS VARCHAR) AS pcn_en_printed, --137-- null string
        CAST(NULL AS VARCHAR) AS pcn_hold_released, --138-- null string
        CAST(NULL AS VARCHAR) AS pcn_dvla_response, --139-- null string
        CAST(NULL AS VARCHAR) AS pcn_dvla_request, --140-- null string
        CAST(NULL AS VARCHAR) AS pcn_full_rate_uplift, --141-- null string
        CAST(NULL AS VARCHAR) AS pcn_hold_until, --142-- null string
        CAST(NULL AS VARCHAR) AS pcn_lifted_at, --143-- null string
        CAST(NULL AS VARCHAR) AS pcn_lifted_by, --144-- null string
        CAST(NULL AS VARCHAR) AS pcn_loaded, --145-- null string
        CAST(NULL AS VARCHAR) AS pcn_nor_sent, --146-- null string
        CAST(NULL AS VARCHAR) AS pcn_notice_held, --147-- null string
        CAST(NULL AS VARCHAR) AS pcn_ofr_printed, --148-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_printed, --149-- null string
        CAST(NULL AS VARCHAR) AS pcn_reissue_nto_requested, --150-- null string
        CAST(NULL AS VARCHAR) AS pcn_reissue_pcn, --151-- null string
        CAST(NULL AS VARCHAR) AS pcn_set_back_to_pre_cc_stage, --152-- null string
        CAST(NULL AS VARCHAR) AS pcn_vehicle_released_for_auction, --153-- null string
        CAST(NULL AS VARCHAR) AS pcn_warrant_issued, --154-- null string
        CAST(NULL AS VARCHAR) AS pcn_warrant_redistributed, --155-- null string
        CAST(NULL AS VARCHAR) AS pcn_warrant_request_granted, --156-- null string
        CAST(NULL AS VARCHAR) AS pcn_ad_hoc_vq4_request, --157-- null string
        CAST(NULL AS VARCHAR) AS pcn_paper_vq5_received, --158-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_buslane, --159-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_pre_debt, --160-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_collection, --161-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_drr, --162-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_cc, --163-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_nto, --164-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_print, --165-- null string
        CAST(NULL AS VARCHAR) AS pcn_warning_notice_extracted_for_print, --166-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_ofr, --167-- null string
        CAST(NULL AS VARCHAR) AS pcn_pcn_extracted_for_warrant_request, --168-- null string
        CAST(NULL AS VARCHAR) AS pcn_pre_debt_new_debtor_details, --169-- null string
        CAST(NULL AS VARCHAR) AS pcn_importdattime, --170-- null string
        CAST(NULL AS VARCHAR) AS pcn_importdatetime, --171-- null string
        CAST('' AS VARCHAR) AS pcn_import_year, --172-- empty string
        CAST('' AS VARCHAR) AS pcn_import_month, --173-- empty string
        CAST('' AS VARCHAR) AS pcn_import_day, --174-- empty string
        CAST('' AS VARCHAR) AS pcn_import_date, --175-- empty string

        /*Teams data*/
        t.t_start_date,
        t.t_end_date,
        t.t_team,
        t.t_team_name,
        t.t_role,
        t.t_forename,
        t.t_surname,
        t.t_full_name,
        t.t_qa_doc_created_by,
        t.t_qa_doc_full_name,
        t.t_post_title,
        t.t_notes,
        t.t_import_date,

        /* Partition columns moved to the end to keep schema alligned */
        d.import_year,
        d.import_month,
        d.import_day,
        CAST(d.import_date AS VARCHAR) AS import_date

    FROM downtime d
    LEFT JOIN team t
        ON UPPER(t.t_full_name) = UPPER(d.Response_written_by) --downtime officer full name
)
SELECT * FROM liberator_with_team
UNION
SELECT * FROM google_form
--order by downtime_timestamp desc
;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
