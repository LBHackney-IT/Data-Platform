"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "Parking_Foreign_VRM_PCNs"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
/*************************************************************************************************************************
 Parking_Foreign_VRM_PCNs

 This SQL creates the list of VRMs against the current valid Permits

 02/03/2022 - Create Query
 *************************************************************************************************************************/
With PCN_Raw as (
        select *
        from "dataplatform-prod-liberator-raw-zone".liberator_pcn_tickets
        Where Import_Date = (
                        Select MAX(Import_Date)
                        from "dataplatform-prod-liberator-raw-zone".liberator_pcn_tickets
                )
                and lower(foreignvehiclecountry) = 'y'
)
SELECT PCN,
        cast(pcnissuedatetime as timestamp) as pcnissuedatetime,
        pcn_canx_date,
        A.cancellationgroup,
        A.cancellationreason,
        street_location,
        whereonlocation,
        zone,
        usrn,
        A.contraventioncode,
        debttype,
        A.vrm,
        vehiclemake,
        vehiclemodel,
        vehiclecolour,
        ceo,
        isremoval,
        A.progressionstage,
        lib_payment_received as payment_received,
        whenpaid as PaymentDate,
        noderef,
        replace(replace(ticketnotes, '\r', ''), '\n', '') as ticketnotes,
        cast(current_timestamp as timestamp) as ImportDateTime,
        format_datetime(current_date, 'yyyy') AS import_year,
        format_datetime(current_date, 'MM') AS import_month,
        format_datetime(current_date, 'dd') AS import_day,
        format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full as A
        INNER JOIN PCN_Raw as B ON A.pcn = B.ticketserialnumber
Where ImportDateTime = (
                Select MAX(ImportDateTime)
                from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
        )
        and warningflag = 0
Order By pcnissuedatetime;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
