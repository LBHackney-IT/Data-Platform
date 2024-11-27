"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "Parking_cycle_hangar_interim_wait_list"

# The exact same query prototyped in pre-prod(stg) orprod Athena
query_on_athena = """
/*********************************************************************************
Parking_cycle_hangar_interim_wait_list

This SQL binds the interim waiting list to the spatial llpg data

27/11/2024 - Create Query
*********************************************************************************/
/* Obtain the latest llpg data */
with llpg as (
    SELECT * FROM "parking-refined-zone".spatially_enriched_liberator_permit_llpg 
    WHERE import_date = (Select MAX(import_date) 
                from "parking-refined-zone".spatially_enriched_liberator_permit_llpg))

/* Collect and output the imterim Waiting list and link records to above */
SELECT 
    forename, surname, email, party_id_to, party_id, A.uprn, A.address1, A.address2, A.postcode,
    A.x, A.y, A.lat, A.long, housing_estate,
    
    format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS importdatetime,

    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM "parking-raw-zone".parking_parking_cycle_hangar_manual_waiting_list as A
LEFT JOIN llpg as B ON cast(A.uprn as decimal(20,0)) = B.uprn
WHERE A.import_Date = format_datetime(current_date, 'yyyyMMdd')
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
