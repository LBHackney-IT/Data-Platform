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
/*********************************************************************************
Parking_Cycle_Hangar_MET_FAIL_Monthly_Format

Temp SQL that formats the cycle hangar managment records For pivot report

09/12/2022 - Create Query
05/07/2023 - rewrite to remove Calendar data
24/01/2024 - change date_fixed to repair_date because field names have been changed
                in google
25/01/2024 - add checks for blank sign off month/year!
26/01/2024 - remove duplicated records
*********************************************************************************/

WITH
  Defect_Basic as (
    SELECT
      ref_no as reference_no,
      hangar_corral_no,
      CAST(
        CASE
          When length (reported_date) = 4 Then '2022' || '-0' || substr (reported_date, 4, 2) || '-' || substr (reported_date, 1, 2)
          When length (reported_date) = 5 Then '2022' || '-' || substr (reported_date, 4, 2) || '-' || substr (reported_date, 1, 2)
          When length (reported_date) = 8 Then '20' || substr (reported_date, 7, 2) || '-' || substr (reported_date, 4, 2) || '-' || substr (reported_date, 1, 2)
          When reported_date like '%/%' Then substr (reported_date, 7, 4) || '-' || substr (reported_date, 4, 2) || '-' || substr (reported_date, 1, 2)
          ELSE substr (cast(reported_date as varchar), 1, 10)
        END as date
      ) as reported_date,
      CAST(
        CASE
          When repair_date like '%/%' Then substr (repair_date, 7, 4) || '-' || substr (repair_date, 4, 2) || '-' || substr (repair_date, 1, 2)
          ELSE substr (cast(repair_date as varchar), 1, 10)
        END as date
      ) as repair_date,
      CAST(
        CASE
          When repair_date like '%/%' Then substr (repair_date, 7, 4) || '-' || substr (repair_date, 4, 2) || '-01'
          ELSE substr (cast(repair_date as varchar), 1, 8) || '01'
        END as date
      ) as Month_repair_date,
      reported_issues_category,
      permanent_action_taken,
      turn_around_time_week_days,
      target_turn_around,
      met_not_met,
      time_taken,
      hangar_or_corral,
      /* Add the collection of signoff month & year */
      CASE
        When sign_off_year != '1899'
        AND sign_off_month != '' Then sign_off_month
        ELSE CASE
          When repair_date like '%/%' Then substr (repair_date, 4, 2)
          ELSE substr (cast(repair_date as varchar), 6, 2)
        END
      END as sign_off_month,
      CASE
        When sign_off_year != '1899'
        AND sign_off_year != '' Then sign_off_year
        ELSE CASE
          When repair_date like '%/%' Then substr (repair_date, 7, 4)
          ELSE substr (cast(repair_date as varchar), 1, 4)
        END
      END as sign_off_year
    FROM
      "parking-raw-zone".parking_parking_ops_cycle_hangar_mgt
    WHERE
      import_date = (
        Select
          MAX(import_date)
        FROM
          "parking-raw-zone".parking_parking_ops_cycle_hangar_mgt
      )
      AND length (ltrim (rtrim (reported_date))) > 0
      AND met_not_met not IN ('#VALUE!', '#N/A')
      AND length (ltrim (rtrim (repair_date))) > 0
  ),
  /*** Tom has informed me that I cannot use the Repair date, but use the sigh off month & year
  USe these fields to recreate Month_repair_date ***/
  Defect as (
    SELECT
      reference_no,
      hangar_corral_no,
      reported_date,
      repair_date,
      CAST(
        sign_off_year || '-' || sign_off_month || '-01' as date
      ) as Month_repair_date,
      reported_issues_category,
      permanent_action_taken,
      turn_around_time_week_days,
      target_turn_around,
      met_not_met,
      time_taken,
      hangar_or_corral,
      sign_off_month,
      sign_off_year
    FROM
      Defect_Basic
  ),
  /********************************************************************************
  Obtain the category totals
  ********************************************************************************/
  category_totals as (
    SELECT
      Month_repair_date,
      met_not_met,
      count(*) as Total_Met_Fail
    FROM
      Defect
    WHERE
      repair_date >=
      -- date_add(cast(substr(cast(current_date
      --                 as varchar), 1, 8)||'01' as date), -365)
      date_add (
        'day',
        -365,
        cast(
          substr (cast(current_date as varchar), 1, 8) || '01' as date
        )
      )
      AND met_not_met = 'Fail'
    GROUP BY
      Month_repair_date,
      met_not_met
    UNION ALL
    SELECT
      Month_repair_date,
      met_not_met,
      count(*) as Total_Met_Fail
    FROM
      Defect
    WHERE
      repair_date >=
      -- date_add(cast(substr(cast(current_date
      --                 as varchar), 1, 8)||'01' as date), -365)
      date_add (
        'day',
        -365,
        cast(
          substr (cast(current_date as varchar), 1, 8) || '01' as date
        )
      )
      AND met_not_met = 'Met'
    GROUP BY
      Month_repair_date,
      met_not_met
    UNION ALL
    SELECT
      Month_repair_date,
      met_not_met,
      count(*) as Total_Met_Fail
    FROM
      Defect
    WHERE
      repair_date >=
      -- date_add(cast(substr(cast(current_date
      --                 as varchar), 1, 8)||'01' as date), -365)
      date_add (
        'day',
        -365,
        cast(
          substr (cast(current_date as varchar), 1, 8) || '01' as date
        )
      )
      AND met_not_met = 'N/A'
    GROUP BY
      Month_repair_date,
      met_not_met
  ),
  Categories as (
    SELECT distinct
      A.Month_repair_date
    FROM
      Defect as A
  ),
  /********************************************************************************
  Obtain and format the totals
  ********************************************************************************/
  Category_Format as (
    SELECT
      A.Month_repair_date,
      CASE
        When B.Total_Met_Fail is not NULL Then B.Total_Met_Fail
        Else 0
      END as Total_Fail,
      CASE
        When C.Total_Met_Fail is not NULL Then C.Total_Met_Fail
        Else 0
      END as Total_Met,
      CASE
        When D.Total_Met_Fail is not NULL Then D.Total_Met_Fail
        Else 0
      END as Total_NA
    FROM
      category_totals as A
      LEFT JOIN category_totals as B ON A.Month_repair_date = B.Month_repair_date
      AND B.met_not_met = 'Fail'
      LEFT JOIN category_totals as C ON A.Month_repair_date = C.Month_repair_date
      AND C.met_not_met = 'Met'
      LEFT JOIN category_totals as D ON A.Month_repair_date = D.Month_repair_date
      AND D.met_not_met = 'N/A'
    WHERE
      A.Month_repair_date >=
      -- date_add(cast(substr(cast(current_date
      --                 as varchar), 1, 8)||'01' as date), -365)
      date_add (
        'day',
        -365,
        cast(
          substr (cast(current_date as varchar), 1, 8) || '01' as date
        )
      )
      AND A.Month_repair_date <= current_date
  ),
  /** De-Dupe the above data **/
  Category_Format_deDupe as (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY
          Month_repair_date,
          Total_Fail,
          Total_Met,
          Total_NA
        ORDER BY
          Month_repair_date,
          Total_Fail,
          Total_Met,
          Total_NA DESC
      ) row_num1
    FROM
      Category_Format
  ),
  /********************************************************************************
  Calculate the monthly totals & %
  ********************************************************************************/
  Total as (
    SELECT
      Month_repair_date,
      'Total' as Category,
      SUM(cast(Total_Met as double) + Total_Fail + Total_NA) as Grand_total
    FROM
      Category_Format_deDupe
    Where
      row_num1 = 1
    GROUP BY
      Month_repair_date
  ),
  Total_Percentage as (
    SELECT
      Month_repair_date,
      'KPI_%' as Category,
      (
        CAST(
          CASE
            When Total_Met + Total_Fail = 0
            AND Total_Met != 0 Then 100
            When Total_Met + Total_Fail = 0
            AND Total_Met = 0 Then 0
            ELSE cast(Total_Met as double) / (Total_Met + Total_Fail)
          END as decimal(8, 2)
        ) * 100
      ) as KPI
    FROM
      Category_Format_deDupe
    Where
      row_num1 = 1
  ),
  /********************************************************************************
  Format the output
  ********************************************************************************/
  Format_Report as (
    SELECT
      Month_repair_date,
      '' as Category,
      'Fail' as Total_Met_Fail,
      Total_Fail as Total
    FROM
      Category_Format_deDupe
    UNION ALL
    SELECT
      Month_repair_date,
      '' as Category,
      'Met' as Total_Met_Fail,
      Total_Met as Total
    FROM
      Category_Format_deDupe
    UNION ALL
    SELECT
      Month_repair_date,
      '' as Category,
      'N/A' as Total_Met_Fail,
      Total_NA as Total
    FROM
      Category_Format_deDupe
    UNION ALL
    SELECT
      Month_repair_date,
      Category,
      '' as Total_Met_Fail,
      Grand_total
    FROM
      Total
    UNION ALL
    SELECT
      Month_repair_date,
      Category,
      '' as Total_Met_Fail,
      KPI
    FROM
      Total_Percentage
  ),
  Data_Dedupe as (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY
          month_repair_date,
          category,
          total_met_fail
        ORDER BY
          month_repair_date,
          category,
          total_met_fail DESC
      ) row_num
    FROM
      Format_Report
  )
  /********************************************************************************
  Ouput data
  ********************************************************************************/
SELECT
  Month_repair_date,
  Category,
  Total_Met_Fail,
  Total,
  format_datetime (
    CAST(CURRENT_TIMESTAMP AS timestamp),
    'yyyy-MM-dd HH:mm:ss'
  ) AS ImportDateTime,
  format_datetime (current_date, 'yyyy') AS import_year,
  format_datetime (current_date, 'MM') AS import_month,
  format_datetime (current_date, 'dd') AS import_day,
  format_datetime (current_date, 'yyyyMMdd') AS import_date
FROM
  Data_Dedupe
WHERE
  row_num = 1
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
