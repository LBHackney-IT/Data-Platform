"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_bailiff_totals"

# The exact same query prototyped in pre-prod(stg) orprod Athena
query_on_athena = """
/*********************************************************************************
Parking_Bailiff_Totals

This SQL summeries the number of Warrants issues against the total Income

20/11/2024 - Create Query
*********************************************************************************/
/*** Warrants ***/
with bailiff_warrants as (
    SELECT *, cast(substr(cast(warrantissuedate as varchar), 1, 8)||'01' as date) as Bailiff_Date 
    FROM "dataplatform-stg-liberator-raw-zone".liberator_pcn_bailiff
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),

/*** Obtain the Cedar payments ***/
cedar_pay as (
    SELECT *, 
    CAST(substr(cast(trandate as varchar), 7, 4)||'-'||
    substr(cast(trandate as varchar), 4, 2)||'-01' as date) as cedar_month
    FROM "parking-raw-zone".cedar_parking_payments
    WHERE import_Date = (Select MAX(import_date) from "parking-raw-zone".cedar_parking_payments)
    AND description = 'NBI'),

/*** Summerise the payments ***/
Cedar_Summ as (
    SELECT
        cedar_month,
        -(sum(cast(financialvalue as double))) as Monthly_Paid
    FROM cedar_pay
    group by cedar_month),

/*** Summerise the warrants ***/
warrant_sum as (
    SELECT
        Bailiff_Date,
        count(*) as Monthly_Totals
    FROM  bailiff_warrants
    group by Bailiff_Date)

/*** Bring the two togather ***/
SELECT
    A.*, B.*,
    
    format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS importdatetime,
    format_datetime(current_date, 'yyyy')       AS import_year,
    format_datetime(current_date, 'MM')         AS import_month,
    format_datetime(current_date, 'dd')         AS import_day,
    format_datetime(current_date, 'yyyyMMdd')   AS import_date
FROM warrant_sum as A
LEFT JOIN Cedar_Summ as B ON A.Bailiff_Date = B.cedar_month
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
