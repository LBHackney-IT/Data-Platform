/******************************************************************************************************************************
Parking_CEO_Average_On_Street_hrs_mins_secs

This SQL creates the average CEO figures for time on street, breaks, etc

15/11/2021 - create SQL

******************************************************************************************************************************/
/*** Collect the parking_ceo_on_street data ***/

WITH On_Street AS (
   SELECT
      ceo, patrol_date, officer_patrolling_date, street, cpzname,
      status_flag, beat, beatname, timeonstreet_secs
   FROM "dataplatform-prod-liberator-refined-zone"."parking_ceo_on_street"
   WHERE import_date = (SELECT MAX(import_date) FROM "dataplatform-prod-liberator-refined-zone"."parking_ceo_on_street")
),

CEO_TimeOnStreet_Summary AS (
   SELECT
      ceo, patrol_date,
      CAST(CONCAT(SUBSTRING(CAST(patrol_date AS varchar), 1, 7), '-01') AS date) AS MonthYear,
      SUM(timeonstreet_secs) AS CEODailyBeatTime_secs
   FROM On_Street
   WHERE timeonstreet_secs > 0
   GROUP BY ceo, patrol_date
   ORDER BY ceo, patrol_date
),

Monthly_AVG AS (
   SELECT
      MonthYear, 
      AVG(CEODailyBeatTime_secs) AS AVG_Month,
      DATE_FORMAT(from_unixtime(AVG(CEODailyBeatTime_secs)), '%H:%i:%s') AS Format_Avg
   FROM CEO_TimeOnStreet_Summary
   GROUP BY MonthYear
   ORDER BY MonthYear
),

Start_Time AS (
   SELECT
      ceo, patrol_date, officer_patrolling_date AS StartTime
   FROM On_Street
   WHERE beatname != ''
   AND status_flag IN ('SSS')
),

First_Street_Time AS (
   SELECT
      ceo, patrol_date, MIN(officer_patrolling_date) AS FirstBeatStreet
   FROM On_Street
   WHERE beatname != ''
   AND status_flag IN ('SS')
   GROUP BY ceo, patrol_date
),

Time_To_Beat_Street AS (
   SELECT
      A.ceo, A.patrol_date, 
      CAST(CONCAT(SUBSTRING(CAST(A.patrol_date AS varchar), 1, 7), '-01') AS date) AS MonthYear,
      StartTime, FirstBeatStreet,
      DATE_DIFF('second', CAST(StartTime AS timestamp), CAST(FirstBeatStreet AS timestamp)) AS Secs_to_First_Beat_Street
   FROM Start_Time AS A
   LEFT JOIN First_Street_Time AS B 
   ON A.ceo = B.ceo AND A.patrol_date = B.patrol_date
),

AVG_Time_to_Beat AS (
   SELECT
      MonthYear,
      CASE
         WHEN AVG(Secs_to_First_Beat_Street) >= 43200 THEN
            DATE_FORMAT(from_unixtime(AVG(Secs_to_First_Beat_Street)), '%H:%i:%s')
         ELSE 
            DATE_FORMAT(from_unixtime(AVG(Secs_to_First_Beat_Street)), '%i:%s')
      END AS Format_Total_Avg
   FROM Time_To_Beat_Street
   GROUP BY MonthYear
),

CEO_Break_Full AS (
   SELECT
      officer_shoulder_no, ceo_protrol_date,
      CAST(CONCAT(SUBSTRING(CAST(ceo_protrol_date AS varchar), 1, 7), '-01') AS date) AS MonthYear,
      total_break, timeonstreet_secs
   FROM "dataplatform-prod-liberator-refined-zone"."parking_ceo_summary"
   WHERE import_date = (SELECT MAX(import_date) FROM "dataplatform-prod-liberator-refined-zone"."parking_ceo_summary")
),

Monthly_Break_AVG AS (
   SELECT
      MonthYear,
      AVG(total_break) AS AVG_Break_Month,
      CASE
         WHEN AVG(total_break) >= 43200 THEN
            DATE_FORMAT(from_unixtime(AVG(total_break)), '%H:%i:%s')
         ELSE 
            DATE_FORMAT(from_unixtime(AVG(total_break)), '%i:%s')
      END AS Format_Break_Avg,
      AVG(timeonstreet_secs) AS AVG_Total_Month,
      DATE_FORMAT(from_unixtime(AVG(timeonstreet_secs)), '%H:%i:%s') AS Format_Total_Avg
   FROM CEO_Break_Full
   GROUP BY MonthYear
   ORDER BY MonthYear
)

SELECT
   A.MonthYear,
   CAST(A.Format_Total_Avg AS varchar) AS Avg_Time_out,
   CAST(B.Format_Avg AS varchar) AS Avg_Time_on_Beat,
   CAST(A.Format_Break_Avg AS varchar) AS Avg_Break,
   CAST(C.Format_Total_Avg AS varchar) AS Avg_Time_to_Beat,
   
  /* current_timestamp AS ImportDateTime,
   DATE_FORMAT(CURRENT_DATE, '%Y') AS import_year,
   DATE_FORMAT(CURRENT_DATE, '%m') AS import_month,
   DATE_FORMAT(CURRENT_DATE, '%d') AS import_day,
   DATE_FORMAT(CURRENT_DATE, '%Y%m%d') AS import_date*/
   
   format_datetime (CAST(CURRENT_TIMESTAMP AS timestamp),'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
format_datetime (current_date, 'yyyy') AS import_year,
format_datetime (current_date, 'MM') AS import_month,
format_datetime (current_date, 'dd') AS import_day,
format_datetime (current_date, 'yyyyMMdd') AS import_date
   
FROM Monthly_Break_AVG AS A
LEFT JOIN Monthly_AVG AS B ON A.MonthYear = B.MonthYear
LEFT JOIN AVG_Time_to_Beat AS C ON A.MonthYear = C.MonthYear;
