"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "Parking_motorcycle_monthly_ringgo_payments"

# The exact same query prototyped in pre-prod(stg) orprod Athena
query_on_athena = """
/***********************************************************************************
Parking_motorcycle_monthly_ringgo_payments

The SQL totals the motorcycle ringgo payments and session count, by month
(for selected locations)

17/07/2024 - Create SQL
*********************************************************************************/
/*** Collect the Motorcycle lookup list, from Carly ***/
With MC_Locations as (
    SELECT * FROM "parking-raw-zone".ringgo_mc_locations),

/*** Collect the Ringgo Motorcycle data, from June 2024 ***/
Ringgo_MC as (
    SELECT 
    CASE
        When session_start like '%/%'Then 
            CAST(substr(session_start, 7, 4)||'-'||substr(session_start, 4,2)||'-'||'01' as date)
        ELSE cast(concat(substr(Cast(session_start as varchar(10)),1, 7), '-01') as date) 
    END as MonthYear,
    A.*, B.ringgo_mc_code, B.location
    FROM "parking-raw-zone".ringgo_daily as A 
    INNER JOIN MC_Locations as B ON A.parking_zone = B.ringgo_mc_code
    WHERE A.vehicle_type = 'Motorcycle' AND 
    A.import_date > '20240710'),

/*** Collect the distinct dates ***/
Collect_Months as (
    SELECT Distinct MonthYear FROM Ringgo_MC),

/*** The list of dates is mated with the list of Ringgo 
M/C locations ***/
AddDates as (
Select ringgo_mc_code, location, B.MonthYear as MC_Date
From MC_Locations
CROSS JOIN Collect_Months as B)

/*** Pivot the Ringgo data to total number of sessions & total paid ***/
SELECT 
    ringgo_mc_code, location, MC_Date, 
    CASE
        When SessionCount is NULL Then 0
        Else SessionCount
    END as SessionCount, 
    CASE
        When TotalPaid is NULL Then 0
        Else TotalPaid
    END as TotalPaid,

    format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS import_date_timestamp,
 
    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date

FROM AddDates as A
LEFT JOIN (Select parking_zone_name, parking_zone, 
            MonthYear, COUNT(MonthYear) As SessionCount, 
            SUM(cast(parking_fee as double)) as TotalPaid
            FROM Ringgo_MC
            GROUP BY parking_zone_name, parking_zone,MonthYear) 
            as B ON A.ringgo_mc_code = B.parking_zone AND
            A.MC_Date = B.MonthYear
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
