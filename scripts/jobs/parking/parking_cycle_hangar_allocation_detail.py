"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_cycle_hangar_allocation_detail"

# The exact same query prototyped in pre-prod(stg) orprod Athena
query_on_athena = """
/*******************************************************************************************************************
parking_cycle_hangar_allocation_Details

The SQL details the number of cycle spaces that are occupied
in each cycle hangar. It also identifies the number of Parties
that are on the waiting list. The code has been amended to use
Tom's hangar list

29/10/2024 - Create Query
******************************************************************************************************************/
With TomHangar as (
    SELECT
        asset_no, asset_type, street_or_estate, zone, status, key_number, fob, location_description,
        road_name, postcode, date_installed, easting, northing, road_or_pavement,
        case
            When asset_no like '%Bikehangar_1577%'    Then '1577'
            When asset_no like '%Bikehangar_H1439%'   Then 'H1439'
            When asset_no like '%Bikehangar_H1440%'   Then 'Hangar_H1440'
            When asset_no like '%Bikehangar_1435%'    Then 'Bikehangar_H1435'
            ELSE replace(asset_no, ' ','_')
        END as HangarID
    from "parking-raw-zone".parking_parking_ops_cycle_hangar_list
    WHERE import_Date = (Select MAX(import_date) from "parking-raw-zone".parking_parking_ops_cycle_hangar_list)
    AND asset_type = 'Hangar' AND lower(status) IN ('active', 'estate locked gate issue')
    /** 20-08-2024 add check for blank records **/
    AND Length(trim(asset_no))> 2),

/*** Get the Hangar details from Liberator ***/
HangarDetails AS (
    SELECT A.ID ,
        HANGAR_TYPE ,
        HANGAR_ID ,
        IN_SERVICE ,
        MAINTENANCE_KEY ,
        SPACES ,
        HANGAR_LOCATION ,
        USRN ,
        LATITUDE ,
        LONGITUDE ,
        START_OF_LIFE ,
        END_OF_LIFE,
    ROW_NUMBER() OVER (PARTITION BY HANGAR_TYPE, HANGAR_ID, IN_SERVICE, MAINTENANCE_KEY, SPACES, 
                                        HANGAR_LOCATION, USRN, LATITUDE,LONGITUDE, START_OF_LIFE, END_OF_LIFE
    ORDER BY HANGAR_TYPE, HANGAR_ID, IN_SERVICE, MAINTENANCE_KEY, SPACES, HANGAR_LOCATION, USRN, LATITUDE, LONGITUDE,
                      START_OF_LIFE, END_OF_LIFE DESC) AS ROW
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_details as A
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    ORDER BY  HANGAR_ID),

/*** Party List ***/
Licence_Party as (
    SELECT * from "dataplatform-stg-liberator-raw-zone".liberator_licence_party
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),
/*******************************************************************************
Cycle Hangar allocation details
*******************************************************************************/
Cycle_Hangar_allocation as (
    SELECT
        *,
        ROW_NUMBER() OVER ( PARTITION BY hanger_id, trim(upper(space))
            ORDER BY hanger_id, trim(upper(space)), date_of_allocation DESC, fee_due_date DESC, id DESC) row_num
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_allocations
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND key_issued = 'Y' AND length(key_id) > 2 AND space != 'null')

SELECT
    hanger_id, asset_no, asset_type, street_or_estate, zone, status,location_description, road_name, 
    C.postcode as Hangar_Postcode, date_installed, easting, northing	road_or_pavement, key_id,USRN,
    space, key_issued, date_of_allocation, allocation_status, fee_due_date,
    A.party_id, title, first_name, surname, 	
    address1, address2,	address3, D.postcode,	uprn, telephone_number, email_address,

    format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp), 
                        'yyyy-MM-dd HH:mm:ss') AS importdatetime,

    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
				
from Cycle_Hangar_allocation as A
LEFT JOIN TomHangar     as C ON A.hanger_id = C.HangarID
LEFT JOIN Licence_Party as D ON A.party_id = D.business_party_id
LEFT JOIN HangarDetails as E ON A.hanger_id = E.HANGAR_ID
where row_num = 1 AND allocation_status not IN ('cancelled', 'key_returned','key_not_returned')
ORDER BY hanger_id, space
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
