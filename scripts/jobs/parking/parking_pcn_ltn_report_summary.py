"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "Parking_PCN_LTN_Report_Summary"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
/*************************************************************************************************************************
 Parking_PCN_LTN_Report_Summary

 The SQL builds the PCN Low Traffic Network figures, for use with the answering of the LTN FOI's

 12/07/2021 - Create SQL.
 *************************************************************************************************************************/
SELECT concat(
                substr(Cast(pcnissuedate as varchar(10)), 1, 7),
                '-01'
        ) AS IssueMonthYear,
        street_location,
        COUNT(distinct pcn) AS PCNs_Issued,
        CAST(
                SUM(cast(lib_payment_received as double)) as decimal(11, 2)
        ) AS Total_Amount_Paid,
        cast(current_timestamp as timestamp) as ImportDateTime,
        format_datetime(current_date, 'yyyy') AS import_year,
        format_datetime(current_date, 'MM') AS import_month,
        format_datetime(current_date, 'dd') AS import_day,
        format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full as A
WHERE warningflag = 0
        and isvda = 0
        and isvoid = 0
        AND import_date =(
                select max(import_date)
                from "dataplatform-prod-liberator-refined-zone".pcnfoidetails_pcn_foi_full
        )
        AND vrm != 'T123EST'
        AND contraventioncode = '52'
        AND street_location IN (
                'Allen Road',
                'Ashenden Road junction of Glyn Road',
                'Barnabas Road JCT Berger Road',
                'Barnabas Road JCT Oriel Road',
                'Brooke Road (E)',
                'Brooke Road junction of Evering Road',
                'Dove Row',
                'Gore Road junction of Lauriston Road.',
                'Hyde Road',
                'Hyde Road JCT Northport Street',
                'Lee Street junction of Stean Street',
                'Maury Road junction of Evering Road',
                'Meeson Street junction of Kingsmead Way',
                'Nevill Road junction of Osterley Road',
                'Neville Road junction of Osterley Road',
                'Pitfield Street (F)',
                'Pitfield Street JCT Hemsworth Street',
                'Powell Road junction of Kenninghall Road',
                'Pritchard`s Road',
                'Pritchards Road',
                'Richmond Road junction of Greenwood Road',
                'Shepherdess Walk',
                'Ufton Road junction of Downham Road',
                'Wilton Way junction of Greenwood Road'
        )
GROUP BY concat(
                substr(Cast(pcnissuedate as varchar(10)), 1, 7),
                '-01'
        ),
        street_location,
        import_date,
        import_day,
        import_month,
        import_year;
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
