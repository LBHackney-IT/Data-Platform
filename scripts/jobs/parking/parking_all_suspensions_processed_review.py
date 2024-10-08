"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_all_suspensions_processed_review"

# The exact same query prototyped in pre-prod(stg) orprod Athena
query_on_athena = """
/*********************************************************************************
parking_all_suspensions_processed_review

SQL TO create the ALL of the unique Suspension activities (accept/amend/reject/etc.)
that have been processed

20/02/2024 - Create Query
*********************************************************************************/
/** Obtain the Suspension activity **/
With Sus_Activity_Approved as (
  SELECT 
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece, activity_by, cast(activity_date as date)
        ORDER BY permit_referece, activity_by, activity_date DESC) R1
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_activity
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND permit_referece like 'HYS%' 
    AND (lower(activity) like '%approved%' OR lower(activity) like '%amend%')
    AND activity_by != 'system' and activity_by not like '%@%'),

Sus_Activity_rejected as (
    SELECT 
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece, activity_by, cast(activity_date as date)
        ORDER BY permit_referece, activity_by, activity_date DESC) R2
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_activity
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND permit_referece like 'HYS%' 
    AND lower(activity) like '%reject%' 
    AND activity_by != 'system' and activity_by not like '%@%'),

Sus_Activity_cancelled as (
    SELECT 
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece, activity_by, cast(activity_date as date)
        ORDER BY permit_referece, activity_by, activity_date DESC) R3
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_activity
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND permit_referece like 'HYS%' 
    AND lower(activity) like '%cancelled%' 
    AND activity_by != 'system' and activity_by not like '%@%'),  

Sus_Activity_additional as (
    SELECT 
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece, activity_by, cast(activity_date as date)
        ORDER BY permit_referece, activity_by, activity_date DESC) R4
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_activity
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND permit_referece like 'HYS%' 
    AND lower(activity) like '%additional%'
    AND activity_by != 'system' and activity_by not like '%@%'),
    
Sus_Activity_duration as (
    SELECT 
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece, activity_by, cast(activity_date as date)
        ORDER BY permit_referece, activity_by, activity_date DESC) R5
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_activity
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND permit_referece like 'HYS%' 
    AND lower(activity) like '%suspension duration changed%'
    AND activity_by != 'system' and activity_by not like '%@%'),    
    
 Sus_Activity_refund as (
    SELECT 
        permit_referece, activity_date, activity,activity_by,
        ROW_NUMBER() OVER ( PARTITION BY permit_referece, activity_by, cast(activity_date as date)
        ORDER BY permit_referece, activity_by, activity_date DESC) R6
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_activity
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND permit_referece like 'HYS%' 
    AND lower(activity) like '%Manual refund processed%'
    AND activity_by != 'system' and activity_by not like '%@%'),

Sus_Activity as (
    SELECT * FROM Sus_Activity_Approved
    WHERE R1 = 1
    union
    SELECT * FROM Sus_Activity_rejected
    WHERE R2 = 1
    union
    SELECT * FROM Sus_Activity_cancelled
    WHERE R3 = 1
    union
    SELECT * FROM Sus_Activity_additional
    WHERE R4 = 1   
    union
    SELECT * FROM Sus_Activity_duration
    WHERE R5 = 1
    union
    SELECT * FROM Sus_Activity_refund
    WHERE R6 = 1),

/*** Calendar import ***/
Calendar as (
Select 
    *,
    CAST(CASE
        When date like '%/%'Then substr(date, 7, 4)||'-'||
                                substr(date, 4, 2)||'-'||
                                substr(date, 1, 2)
        ELSE substr(date, 1, 10)
    END as date) as Format_date
    From "parking-raw-zone".calendar
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),

CalendarMAX as (
Select MAX(fin_year) as Max_Fin_Year From calendar
WHERE import_date = (Select MAX(import_date) from calendar)),

/*** Select the Suspension denormal data ***/
Suspensions_basic as (
    SELECT 
        suspensions_reference, 
        applicationdate
    FROM "dataplatform-stg-liberator-refined-zone".parking_suspension_denormalised_data
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),

Suspensions as (
    SELECT 
        B.suspensions_reference, 
        B.applicationdate,
        A.activity_date,
        date_diff('day',B.applicationdate,A.activity_date) as DateDiff,
        A.activity, A.activity_by
    FROM Sus_Activity as A
    INNER JOIN Suspensions_basic as B 
                ON A.permit_referece = B.suspensions_reference)

/** Output the data **/
SELECT 
    A.*,

    /** Obtain the Fin year flag and fin year ***/
    CASE 
        When H.Fin_Year = (Select Max_Fin_Year From CalendarMAX)                                    Then 'Current'
        When H.Fin_Year = (Select CAST(Cast(Max_Fin_Year as int)-1 as varchar(4)) From CalendarMAX) Then 'Previous'
        Else ''
    END as Fin_Year_Flag,
       
    H.Fin_Year,
    
    format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp), 
            'yyyy-MM-dd HH:mm:ss') AS import_date_timestamp,

    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM Suspensions as A
LEFT JOIN Calendar as H 
    ON CAST(substr(cast(applicationdate as varchar),1, 10) as date) = cast(Format_date as date)
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
