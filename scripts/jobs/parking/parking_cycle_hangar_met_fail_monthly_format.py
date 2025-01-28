"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "Parking_Cycle_Hangar_MET_FAIL_Monthly_Format"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
-- Output to --> "dataplatform-prod-liberator-refined-zone"."Parking_Defect_MET_FAIL_Monthly_Format"
/*********************************************************************************
Parking_Defect_MET_FAIL_Monthly_Format

Temp SQL that formats the defect managment records For pivot report

18/11/2022 - Create Query
21/11/2022 - add sub/grand total(s) and calculate KPI percentage
22/11/2022 - change % calc to make it a decimal
28/07/2023 - add N/A records. Change closed date to a date made up
of sign off month and year NOT repair_date
08/10/2024 - Attempted migration from Spark SQL back to Athena SQL
*********************************************************************************/

WITH Defect_Basic AS (
    SELECT
        reference_no,
        CAST(CASE
            WHEN reported_date LIKE '%0222%' THEN '2022-' ||
                                                  substr(reported_date, 7, 2) || '-' ||
                                                  substr(reported_date, 9, 2)
            WHEN reported_date LIKE '%/%' THEN substr(reported_date, 7, 4) || '-' ||
                                               substr(reported_date, 4, 2) || '-' ||
                                               substr(reported_date, 1, 2)
            ELSE substr(CAST(reported_date AS VARCHAR), 1, 10)
        END AS DATE) AS reported_date,
        CAST(CASE
            WHEN repair_date LIKE '%/%' THEN substr(repair_date, 7, 4) || '-' ||
                                             substr(repair_date, 4, 2) || '-' ||
                                             substr(repair_date, 1, 2)
            ELSE substr(CAST(repair_date AS VARCHAR), 1, 10)
        END AS DATE) AS repair_date,
        CAST(CASE
            WHEN repair_date LIKE '%/%' THEN substr(repair_date, 7, 4) || '-' ||
                                             substr(repair_date, 4, 2) || '-01'
            ELSE substr(CAST(repair_date AS VARCHAR), 1, 8) || '01'
        END AS DATE) AS Month_repair_date,
        CASE
            WHEN category = 'post' THEN 'Post'
            ELSE category
        END AS category,
        date_wo_sent,
        expected_wo_completion_date,
        target_turn_around,
        met_not_met,
        full_repair_category,
        issue,
        engineer,
        CASE
            WHEN sign_off_year != '1899' THEN sign_off_month
            ELSE CASE
                WHEN repair_date LIKE '%/%' THEN substr(repair_date, 4, 2)
                ELSE substr(CAST(repair_date AS VARCHAR), 6, 2)
            END
        END AS sign_off_month,
        CASE
            WHEN sign_off_year != '1899' THEN sign_off_year
            ELSE CASE
                WHEN repair_date LIKE '%/%' THEN substr(repair_date, 7, 4)
                ELSE substr(CAST(repair_date AS VARCHAR), 1, 4)
            END
        END AS sign_off_year
    FROM "parking-raw-zone"."parking_parking_ops_db_defects_mgt"
    WHERE import_date = (SELECT MAX(import_date)
                         FROM "parking-raw-zone"."parking_parking_ops_db_defects_mgt")
    AND LENGTH(LTRIM(RTRIM(reported_date))) > 0
    AND met_not_met NOT IN ('#VALUE!', '#N/A')
    AND LENGTH(LTRIM(RTRIM(repair_date))) > 0
),

/*** Tom has informed me that I cannot use the Repair date, but use the sigh off month & year
USe these fields to recreate Month_repair_date ***/
Defect AS (
    SELECT
        reference_no,
        reported_date,
        repair_date,
        CAST(sign_off_year || '-' || sign_off_month || '-01' AS DATE) AS Month_repair_date,
        category,
        date_wo_sent,
        expected_wo_completion_date,
        target_turn_around,
        met_not_met,
        full_repair_category,
        issue,
        engineer,
        sign_off_month,
        sign_off_year
    FROM Defect_Basic
),

/********************************************************************************
Obtain the category totals
********************************************************************************/
category_totals AS (
    SELECT
        Month_repair_date,
        category,
        met_not_met,
        COUNT(*) AS Total_Met_Fail
    FROM Defect
    WHERE repair_date >=
          date_add('day', -365, CAST(substr(CAST(current_date AS VARCHAR), 1, 8) || '01' AS DATE))
    AND met_not_met = 'Fail'
    GROUP BY Month_repair_date, category, met_not_met
    UNION ALL
    SELECT
        Month_repair_date,
        category,
        met_not_met,
        COUNT(*) AS Total_Met_Fail
    FROM Defect
    WHERE repair_date >=
          date_add('day', -365, CAST(substr(CAST(current_date AS VARCHAR), 1, 8) || '01' AS DATE))
    AND met_not_met = 'Met'
    GROUP BY Month_repair_date, category, met_not_met
    UNION ALL
    SELECT
        Month_repair_date,
        category,
        met_not_met,
        COUNT(*) AS Total_Met_Fail
    FROM Defect
    WHERE repair_date >=
          date_add('day', -365, CAST(substr(CAST(current_date AS VARCHAR), 1, 8) || '01' AS DATE))
    AND met_not_met = 'N/A'
    GROUP BY Month_repair_date, category, met_not_met
),

/********************************************************************************
Obtain the categories
********************************************************************************/
Categories AS (
    SELECT DISTINCT
        A.Month_repair_date,
        B.category
    FROM Defect AS A
    CROSS JOIN (SELECT DISTINCT category FROM Defect) AS B
    WHERE LENGTH(B.category) > 0
),

/********************************************************************************
Obtain and format the totals
********************************************************************************/
Category_Format AS (
    SELECT
        A.Month_repair_date,
        A.category,
        COALESCE(B.Total_Met_Fail, 0) AS Total_Fail,
        COALESCE(C.Total_Met_Fail, 0) AS Total_Met,
        COALESCE(D.Total_Met_Fail, 0) AS Total_NA
    FROM Categories AS A
    LEFT JOIN category_totals AS B ON A.Month_repair_date = B.Month_repair_date
                                    AND A.category = B.category
                                    AND B.met_not_met = 'Fail'
    LEFT JOIN category_totals AS C ON A.Month_repair_date = C.Month_repair_date
                                    AND A.category = C.category
                                    AND C.met_not_met = 'Met'
    LEFT JOIN category_totals AS D ON A.Month_repair_date = D.Month_repair_date
                                    AND A.category = D.category
                                    AND D.met_not_met = 'N/A'
    WHERE A.Month_repair_date >=
          date_add('day', -365, CAST(substr(CAST(current_date AS VARCHAR), 1, 8) || '01' AS DATE))
),

/********************************************************************************
Calculate the KPI %
********************************************************************************/
PDKPI as (
-- Fixed by outputting zero instead: INVALID_CAST_ARGUMENT: Cannot cast DOUBLE 'NaN' to DECIMAL(8, 2) caused by division by SUM(Total_Met + Total_Fail)=zero resulting in "Not a Number".
    SELECT
        Month_repair_date,
        'Total_P&D_KPI_%' as Category,
        CASE
            WHEN SUM(Total_Met + Total_Fail) = 0 THEN 0
            ELSE (cast((SUM(cast(Total_Met as double)) /
                        SUM((Total_Met + Total_Fail))) as decimal(8,2)) * 100)
        END as PD_KPI
    FROM Category_Format
    WHERE category = 'P&D'
    GROUP BY Month_repair_date
),

SLPKPI as (
-- Fixed by outputting zero instead: INVALID_CAST_ARGUMENT: Cannot cast DOUBLE 'NaN' to DECIMAL(8, 2) caused by division by SUM(Total_Met + Total_Fail)=zero resulting in "Not a Number".
    SELECT
        Month_repair_date,
        'Total_Signs_Lines_Posts_KPI_%' as Category,
        CASE
            WHEN SUM(Total_Met + Total_Fail) = 0 THEN 0
            ELSE (cast((SUM(cast(Total_Met as double)) /
                        SUM((Total_Met + Total_Fail))) as decimal(8,2)) * 100)
        END as Signs_Lines_Posts_KPI
    FROM Category_Format
    WHERE category IN ('Lines', 'Post', 'Signs')
    GROUP BY Month_repair_date
),

/********************************************************************************
Obtain the category totals & Grand totals
********************************************************************************/
catgory_totals AS (
    SELECT
        Month_repair_date,
        category || ' Total' AS category,
        SUM(total_met_fail) AS Total
    FROM category_totals
    GROUP BY Month_repair_date, category
),

grand_totals AS (
    SELECT
        Month_repair_date,
        SUM(total_met_fail) AS Total
    FROM category_totals
    GROUP BY Month_repair_date
),

/********************************************************************************
Format the output
********************************************************************************/
Format_Report AS (
    SELECT
        Month_repair_date, category, 'Fail' AS Total_Met_Fail, Total_Fail AS Total
    FROM Category_Format
    UNION ALL
    SELECT
        Month_repair_date, category, 'Met' AS Total_Met_Fail, Total_Met AS Total
    FROM Category_Format
    UNION ALL
    SELECT
        Month_repair_date, category, 'N/A' AS Total_Met_Fail, Total_NA AS Total
    FROM Category_Format
    UNION ALL
    SELECT
        Month_repair_date, Category, '' AS Total_Met_Fail, PD_KPI
    FROM PDKPI
    UNION ALL
    SELECT
        Month_repair_date, Category, '' AS Total_Met_Fail, Signs_Lines_Posts_KPI
    FROM SLPKPI
    UNION ALL
    SELECT
        Month_repair_date, category, '' AS Total_Met_Fail, Total
    FROM catgory_totals
    UNION ALL
    SELECT
        Month_repair_date, 'Total Grand' AS category, '' AS Total_Met_Fail, Total
    FROM grand_totals
)

/********************************************************************************
Ouput data
********************************************************************************/
SELECT
    *,
    date_format(CAST(CURRENT_TIMESTAMP AS TIMESTAMP), '%Y-%m-%d %H:%i:%s') AS ImportDateTime,
    date_format(current_date, '%Y') AS import_year,
    date_format(current_date, '%m') AS import_month,
    date_format(current_date, '%d') AS import_day,
    date_format(current_date, '%Y%m%d') AS import_date
FROM Format_Report;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
