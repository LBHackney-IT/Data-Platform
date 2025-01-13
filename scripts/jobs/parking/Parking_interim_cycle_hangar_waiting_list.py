"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "Parking_interim_cycle_hangar_waiting_list"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
/*********************************************************************************
Parking_interim_cycle_hangar_waiting_list

Process the interim cycle hangar waiting list (supplied by Michael W) to add
additional fields (telephone Number, etc).

23/12/2024 - Create SQL
06/01/2025 - add unsubscribed email
13/01/2025 - add opt-in data
*********************************************************************************/
With Interim_Wait as (
    SELECT
        distinct forename
        ,surname
        ,email
        ,party_id_to
        ,party_id
        ,cast(uprn as decimal) as uprn
        ,address1
        ,address2
        ,post_code
        ,x
        ,y
        ,lat
        ,long
    FROM "parking-raw-zone".interim_cycle_wait_list
    WHERE import_date = (select max(import_date)
                    from "parking-raw-zone".interim_cycle_wait_list)),

/*** Obtain the llpg data ***/
FULL_LLPG as (
    SELECT * From "parking-refined-zone".spatially_enriched_liberator_permit_llpg
    WHERE import_date = (select max(import_date)
                    from "parking-refined-zone".spatially_enriched_liberator_permit_llpg)
    AND address1 not like '%STREET RECORD%'),

STREET_LLPG as (
    SELECT * From "parking-refined-zone".spatially_enriched_liberator_permit_llpg
    WHERE import_date = (select max(import_date)
                    from "parking-refined-zone".spatially_enriched_liberator_permit_llpg)
    AND address1 like '%STREET RECORD%'),

/*** Obtain the Party details, where available ***/
Party as (
    SELECT
        *
    From "dataplatform-stg-liberator-raw-zone".liberator_licence_party
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),

/*** 06/01/2024 - obtain the emails (from Tom) of those parties that are NOT interested in a Hangar***/
unsubscribed_emails as (
    SELECT *,
        ROW_NUMBER() OVER ( PARTITION BY email_address ORDER BY email_address DESC) row1
    FROM "parking-raw-zone".parking_parking_cycle_hangar_unsubscribed_emails
    WHERE import_date = (select max(import_date)
                    from "parking-raw-zone".parking_parking_cycle_hangar_unsubscribed_emails)),

/*** 13/01/2025 added ***/
opt_in_emails as (
    SELECT
        please_note_your_email_address_has_been_prefilled_based_on_your_account_registration_please_do_not_amend_this as email,
        please_select_one_of_the_options_below,
        ROW_NUMBER() OVER ( PARTITION BY please_note_your_email_address_has_been_prefilled_based_on_your_account_registration_please_do_not_amend_this
        ORDER BY please_note_your_email_address_has_been_prefilled_based_on_your_account_registration_please_do_not_amend_this
        DESC) row1
    FROM "parking-raw-zone".parking_parking_opt_in_form_responses 
    WHERE import_date = (select max(import_date) 
                    from "parking-raw-zone".parking_parking_opt_in_form_responses)
    AND please_select_one_of_the_options_below like 'No.%')

SELECT
    A.*, cast(D.telephone_number as varchar) as Telephone_Number,  C.address2 as Street, B.housing_estate, 
    CASE 
        When length(E.email_address) > 1    Then E.email_address
        When length(F.email)> 1             Then F.email
    END as email_address,  

  format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp),
                'yyyy-MM-dd HH:mm:ss') AS import_date_timestamp,

  format_datetime(current_date, 'yyyy') AS import_year,
  format_datetime(current_date, 'MM') AS import_month,
  format_datetime(current_date, 'dd') AS import_day,
  format_datetime(current_date, 'yyyyMMdd') AS import_date

FROM Interim_Wait as A
LEFT JOIN FULL_LLPG as B ON A.uprn = B.UPRN
LEFT JOIN STREET_LLPG as C ON B.USRN = C.USRN
LEFT JOIN Party as D ON A.party_id = D.business_party_id
LEFT JOIN unsubscribed_emails as E ON upper(ltrim(rtrim(A.email))) = upper(ltrim(rtrim(E.email_address)))
        AND E.row1 = 1
LEFT JOIN opt_in_emails as F ON upper(ltrim(rtrim(A.email))) = upper(ltrim(rtrim(F.email)))
        AND F.row1 = 1
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
