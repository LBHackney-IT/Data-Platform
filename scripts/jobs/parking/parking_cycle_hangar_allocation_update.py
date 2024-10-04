"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
Note: python file name should be the same as the table name
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_cycle_hangar_allocation_update"

# The exact same query prototyped in pre-prod(stg) or prod Athena
query_on_athena = """
/*******************************************************************************************************************
parking_cycle_hangar_allocation_update

The SQL details the number of cycle spaces that are occupied
in each cycle hangar. It also identifies the number of Parties
that are on the waiting list. The code has been amended to use
Tom's hangar list

19/10/2023 - Create Query
23/01/2024 - update code to add changes made to the base Google sheet
20/05/2024 - amend to NOT filter out records with NO address (i.e. not matching the Party_ID)
30/05/2024 - rewrite to use the History data
13/06/2024 - slight aendments because of my cock-up!
14/06/2024 - make additional changes because the cycle hangar key_id & space have been swapped
19/06/2024 - trim the allocated space, there are leading spaces in the field!!!
29/07/2024 - change collection of tom's hangars to add an additional status
01/08/2024 - summerise ALL of the allocated PartyIDs (not just those that are active now). Use this list
                to filter out 'allocated' PartyIDs from the Waiting List
19/08/2024 - add additional order by for cycle hangar allocation
20/08/2024 - additional checks for rubbish data!!!!
23/08/2024 - look again at the waiting list!
28/04/2024 - refine the 'hangar_can_be_filled' field case statement
26/09/2024 - add hangar location.
04/10/2024 - add additional checks for the waiting list
******************************************************************************************************************/
/*******************************************************************************
Create a comparison between Toms Hangar list and EStreet
*******************************************************************************/
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
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND asset_type = 'Hangar' AND lower(status) IN ('active', 'estate locked gate issue')
    /** 20-08-2024 add check for blank records **/
    AND Length(trim(asset_no))> 2),

/** 20-08-2024 get ALL of the data AND check for duplicates **/
Hanger as (
    SELECT HangarID as hanger_id, *,
    ROW_NUMBER() OVER ( PARTITION BY HangarID ORDER BY HangarID DESC) H1
    FROM TomHangar),

/** 20/08/2024 I check for duplicates and dont use the data??? change to use**/
Hangar_Comp as (
    SELECT
        asset_no, HangarID, hanger_id
    FROM Hanger as A
    /**LEFT JOIN Hanger as B ON A.HangarID = B.hanger_id AND H1 = 1 remove **/
    WHERE H1 = 1
    UNION ALL
    SELECT 'new_only','new_only','new_only'),

/*******************************************************************************
Obtain the latest Waiting List History
*******************************************************************************/
Wait_History as (
    SELECT A.*,
        ROW_NUMBER() OVER ( PARTITION BY A.party_id,hanger_id ORDER BY A.party_id,hanger_id, updated DESC ) R1
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_waiting_list_history as A
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),
/*******************************************************************************
Create the Waiting list - unique "party_id"
*******************************************************************************/
waiting_list as (
    SELECT A.party_id, A.registration_type, A.hanger_id, A.new_hangars_only, A.offer_made,
        A.uprn, A.registration_date,
        B.party_id as History_party_id, A.hanger_id	as History_hanger_id, B.status_from, B.status_to,
        B.date_from, B.date_to, B.updated, B.created_by, B.registation_date as History_registation_date,
        ROW_NUMBER() OVER ( PARTITION BY A.party_id, A.hanger_id ORDER BY A.party_id, A.hanger_id DESC) row1
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_waiting_list as A
    LEFT JOIN Wait_History as B ON A.party_id = B.party_id AND A.hanger_id = B.hanger_id AND B.R1 = 1
    WHERE A.import_Date = format_datetime(current_date, 'yyyyMMdd')),
/*** Party List ***/
Licence_Party as (
    SELECT * from "dataplatform-stg-liberator-raw-zone".liberator_licence_party
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),
/*** STREET ***/
LLPG as (
    SELECT *
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_llpg
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),
/*******************************************************************************
Cycle Hangar allocation details
*******************************************************************************/
Cycle_Hangar_allocation as (
    SELECT
        *,
        /* 13/06 change order by to include ID */
        /* 14/06 change again to hangar_id and space because there are some hangars with multiple spaces
        allocated to the same Party_id. UPPER(space) because there are records with lowercase space field */
        /* 19/06 trim the space */
        ROW_NUMBER() OVER ( PARTITION BY hanger_id, trim(upper(space))
            ORDER BY hanger_id, trim(upper(space)), date_of_allocation DESC, fee_due_date DESC, id DESC) row_num
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_allocations
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    /* 14/06 change to exclude those records where keys have not been issued AND
    remove those records where the Space and Key ID fields have been switched??? also
    remove those records with null in the space field????*/
    AND key_issued = 'Y' AND length(key_id) > 2 AND space != 'null'),

/*** 23/07/2024 - obtain the last party id/hangar allocation details ***/
Party_ID_Allocation as (
    SELECT
        *,
        ROW_NUMBER() OVER ( PARTITION BY party_id, hanger_id
            ORDER BY party_id, hanger_id, id DESC) row_num
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_allocations
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND key_issued = 'Y' AND length(key_id) > 2 AND space != 'null'),

/** 13/06 total the alloctaion details obtain above */
Alloc_Total as (
    SELECT hanger_id, count(*) as total_alloc
    FROM Cycle_Hangar_allocation
    WHERE row_num = 1 AND allocation_status not IN ('cancelled', 'key_returned','key_not_returned')
    GROUP BY hanger_id),

Street_Rec as (
    SELECT *
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_llpg
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND address1 = 'STREET RECORD'),

/*** 01/08/2024 Summerise the allocatd Party IDs to prevent duplication below **/
Summary_Alloca_PartyID as (
    SELECT party_id,
        ROW_NUMBER() OVER ( PARTITION BY party_id
            ORDER BY party_id DESC) R1
    FROM Party_ID_Allocation
    WHERE row_num = 1),

Cycle_Hangar_Wait_List as (
    SELECT
        A.party_id, first_name, surname, B.uprn as USER_UPRN,
        B.address1, B.address2, B.address3, B.postcode, B.telephone_number, D.Address2 as Street,registration_date
        ,A.hanger_id, E.party_id Allocated_Party_ID, History_party_id, History_hanger_id, status_to, updated
    FROM waiting_list as A
    LEFT JOIN Licence_Party as B ON A.party_id = B.business_party_id
    LEFT JOIN LLPG          as C ON B.uprn = cast(C.UPRN as varchar)
    LEFT JOIN Street_Rec    as D ON C.USRN = D.USRN
    /*LEFT JOIN Summary_Alloca_PartyID as E ON A.party_id = E.party_id AND R1 = 1*/
    LEFT JOIN Cycle_Hangar_allocation as E ON A.party_id = E.party_id  AND row_num = 1 
    WHERE row1= 1 AND E.party_id is NULL AND status_to not IN ('removed','rejected offer','offer accepted')),
/************************************************************
Waiting List CREATED
************************************************************/
/* Amend to use Toms Hangar List */
Estreet_Hanger as (
    SELECT HangarID as hanger_id, 'A' as space, road_name as hangar_location, 1 as H1
    FROM TomHangar
    UNION ALL
    SELECT HangarID as hanger_id, 'B' as space, road_name as hangar_location, 1 as H1
    FROM TomHangar
    UNION ALL
    SELECT HangarID as hanger_id, 'C' as space, road_name as hangar_location, 1 as H1
    FROM TomHangar
    UNION ALL
    SELECT HangarID as hanger_id, 'D' as space, road_name as hangar_location, 1 as H1
    FROM TomHangar
    UNION ALL
    SELECT HangarID as hanger_id, 'E' as space, road_name as hangar_location, 1 as H1
    FROM TomHangar
    UNION ALL
    SELECT HangarID as hanger_id, 'F' as space, road_name as hangar_location, 1 as H1
    FROM TomHangar
    UNION ALL
    SELECT 'new_only', ' ', 'NEWONLY', 1),

Wait_List_Hangar as (
    SELECT A.party_id, A.hanger_id,
    ROW_NUMBER() OVER ( PARTITION BY A.party_id, A.hanger_id
                                    ORDER BY A.party_id, A.hanger_id DESC) H2
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_waiting_list as A
    INNER JOIN Cycle_Hangar_Wait_List as B ON A.party_id = B.party_id AND A.hanger_id = B.hanger_id
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')),

Wait_List_Earlist_Latest as (
    SELECT A.hanger_id, max(A.registration_date) as Max_Date, min(A.registration_date) as Min_Date
    FROM "dataplatform-stg-liberator-raw-zone".liberator_hangar_waiting_list as A
    INNER JOIN Cycle_Hangar_Wait_List as B ON A.party_id = B.party_id
    WHERE import_Date = format_datetime(current_date, 'yyyyMMdd')
    AND A.registration_date not
            IN ('2000-01-01','1900-12-13','1000-04-02','1100-04-02',
                                '1200-04-02','1300-04-02','1400-04-02','2000-12-17','1200-03-24')
    GROUP BY A.hanger_id),

Wait_total as (
    SELECT hanger_id, count(*) as Wait_Total
    FROM Wait_List_Hangar
    WHERE H2 = 1
    GROUP BY hanger_id),

/* 13/06 - correctly use the allocated total against the list of Hangars from Tom */
allocated_Total as (
    SELECT DISTINCT A.hanger_id, A.hangar_location, total_alloc as Total_Allocated
    FROM Estreet_Hanger as A
    LEFT JOIN Alloc_Total as B ON A.hanger_id = B.hanger_id
    WHERE H1 = 1),

Full_Hangar_Data as (
    SELECT
        A.hanger_id, A.hangar_location,
        CASE
            When A.hanger_id = 'new_only' Then 0
            ELSE Total_Allocated
        END as Total_Allocated,
        Wait_Total,
        CASE
            When A.hanger_id = 'new_only' Then 0
            ELSE ( 6 - Total_Allocated)
        END as free_spaces,
        Min_Date as Earlist_Registration_Date,
        Max_Date as Latest_Registration_Date
    FROM allocated_Total as A
    LEFT JOIN Wait_total as B ON A.hanger_id = B.hanger_id
    LEFT JOIN Wait_List_Earlist_Latest as C ON A.hanger_id = C.hanger_id),

/** 20-08-2024 Use the de-dupe data NOT TomHangar **/
Hangar_WAit_List as (
    SELECT
        A.asset_no as Tom_Asset_No, B.hanger_id as HangarID, street_or_estate, zone, location_description,
        hangar_location, postcode, date_installed,
        CASE
            When Total_Allocated is NULL Then 0
            ELSE Total_Allocated
        END as Total_Allocated,
        CASE
            When Wait_Total is NULL OR Wait_Total = 0 Then 0
            ELSE Wait_Total
        END as Wait_Total,
        CASE
            When free_spaces is NULL Then 6
            ELSE free_spaces
        END as free_spaces,
        Earlist_Registration_Date, Latest_Registration_Date
    FROM Hanger as A
    LEFT JOIN Hangar_Comp       as B ON A.asset_no = B.asset_no
    LEFT JOIN Full_Hangar_Data  as C ON B.hanger_id = C.hanger_id
    WHERE H1 = 1),

/*** Output the data ***/
Output as (
    SELECT *,
        CASE
            When Total_Allocated = 6                Then 'N/A'
            /*** 28/08 amend to close the loop of no Wait ttal and free spaces ***/
            When Wait_Total = 0 AND free_spaces > 0 Then 'Yes'
            When Wait_Total >= free_spaces          Then 'Yes'
            Else 'No'
        END as hangar_can_be_filled
    FROM Hangar_WAit_List
    WHERE HangarID is not NULL
    UNION ALL
    SELECT A.Tom_Asset_No, A.HangarID, A.street_or_estate, A.zone, A.location_description,
        A.hangar_location, A.postcode, A.date_installed, A.Total_Allocated, TotalWatch, A.free_spaces,
        C.Earlist_Registration_Date, C.Latest_Registration_Date,
        CASE
            When A.Total_Allocated = 6        Then 'N/A'
            When TotalWatch >= A.free_spaces  Then 'Yes'
            Else 'No'
        END as hangar_can_be_filled
    FROM Hangar_WAit_List as A
    LEFT JOIN (SELECT hanger_id, count(*) as TotalWatch FROM waiting_list
            GROUP BY hanger_id) B ON replace(A.Tom_Asset_No,' ','_') = B.hanger_id
    LEFT JOIN Full_Hangar_Data  as C ON B.hanger_id = C.hanger_id
    WHERE A.HangarID is NULL)

SELECT *,
    CASE
        When hangar_can_be_filled = 'No' AND
            wait_total is not NULL Then free_spaces - Wait_Total
        Else 0
    END as Spaces_that_cannot_be_allocated,

    format_datetime(CAST(CURRENT_TIMESTAMP AS timestamp),
                'yyyy-MM-dd HH:mm:ss') AS import_date_timestamp,

    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM Output
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
