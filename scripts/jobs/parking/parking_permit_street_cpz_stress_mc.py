"""
Only need to change the table name and the query prototyped on the Athena UI
by replacing table_name and query_on_athena
"""

from scripts.helpers.athena_helpers import create_update_table_with_partition
from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")

# The target table in liberator refined zone
table_name = "parking_permit_street_cpz_stress_mc"

# The exact same query prototyped in pre-prod(stg) orprod Athena
query_on_athena = """
/***********************************************************************************
 Parking_Permit_Street_CPZ_Stress

 The SQL builds a list of CPZs and identifies the number of
 Parking spaces (Shared use, Resident, etc) and the number of extant Permits

 22/08/2024 - Create SQL
 *********************************************************************************/
With parking_permit_denormalised_data as (
    SELECT *
    from "dataplatform-stg-liberator-refined-zone".parking_permit_denormalised_data
    where import_date = format_datetime(current_date, 'yyyyMMdd')
),
LLPG as (
    SELECT *
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_llpg
    WHERE import_date = format_datetime(current_date, 'yyyyMMdd')
),
Street_Rec as (
    SELECT *
    FROM "dataplatform-stg-liberator-raw-zone".liberator_permit_llpg
    WHERE import_date = format_datetime(current_date, 'yyyyMMdd')
        AND address1 = 'STREET RECORD'
),
/** Get the Parkmap records **/
Parkmap as (
    SELECT order_type,
        street_name,
        no_of_spaces,
        nsg,
        /** If schedule begins with a Z then use that as the Zone */
        CASE
            When lower(substr(schedule, 1, 1)) = 'z' Then schedule
            When zone is NULL
            AND lower(substr(schedule, 1, 1)) != 'z' Then 'Z56'
            ELSE Zone
        END As Zone
    FROM "parking-raw-zone".geolive_parking_order as A
    WHERE import_date = format_datetime(current_date, 'yyyyMMdd')
        AND order_type IN (
            'Business bay',
            'Estate permit bay',
            'Cashless Shared Use',
            'Permit Bay',
            'Permit Electric Vehicle',
            'Resident bay',
            'Shared Use - Permit/Chargeable',
            'Disabled'
        )
        AND street_name is not NULL
    UNION ALL
    /*** Add M/C Bays ***/
    SELECT 'Motorcycle Bay',
        street_name,
        no_of_spaces,
        nsg,
        /** If schedule begins with a Z then use that as the Zone */
        CASE
            When lower(substr(schedule, 1, 1)) = 'z' Then schedule
            When zone is NULL
            AND lower(substr(schedule, 1, 1)) != 'z' Then 'Z56'
            ELSE Zone
        END As Zone
    FROM "parking-raw-zone".geolive_parking_order as A
    WHERE import_date = format_datetime(current_date, 'yyyyMMdd')
        AND schedule = 'MC.001'
        AND street_name is not NULL
),
/** Summerise the Parkmap records **/
Parkmap_Summary as (
    SELECT 'Business bay' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap as A
    WHERE order_type = 'Business bay'
    GROUP BY zone,
        street_name
    UNION ALL
    SELECT 'Estate permit bay' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type = 'Estate permit bay'
    GROUP BY zone,
        street_name
    UNION ALL
    SELECT 'Shared Use' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN (
            'Cashless Shared Use',
            'Shared Use - Permit/Chargeable'
        )
    GROUP BY zone,
        street_name
    UNION ALL
    SELECT 'Permit Bay' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Permit Bay')
    GROUP BY zone,
        street_name
    UNION ALL
    SELECT 'Resident bay' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Resident bay')
    GROUP BY zone,
        street_name
    UNION ALL
    SELECT 'Disabled' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Disabled')
    GROUP BY zone,
        street_name
        /** M/C Bays **/
    UNION ALL
    SELECT 'Motorcycle Bay' as order_type,
        REPLACE(Zone, 'Zone ', '') As zone,
        street_name,
        SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap as A
    WHERE order_type = 'Motorcycle Bay'
    GROUP BY zone,
        street_name
),
/*** get the VRM details to obtain the m/c flag ***/
MC_Permit_Flag as (
    SELECT *
    from "dataplatform-stg-liberator-raw-zone".liberator_permit_vrm_480
    WHERE import_date = format_datetime(current_date, 'yyyyMMdd')
),
/** Get the Permits records link in the LLPG data **/
Permits as (
    SELECT A.permit_reference,
        A.email_address_of_applicant,
        A.permit_type,
        A.uprn,
        A.address_line_1,
        A.address_line_2,
        A.address_line_3,
        A.postcode,
        C.address2,
        CASE
            When length(trim(A.cpz)) = 1 Then trim(A.cpz)
            ELSE A.cpz
        END cpz,
        A.vrm,
        D.*,
        ROW_NUMBER() OVER (
            PARTITION BY A.email_address_of_applicant,
            A.permit_reference
            ORDER BY A.email_address_of_applicant,
                A.permit_type DESC
        ) r1
    FROM parking_permit_denormalised_data as A
        LEFT JOIN LLPG as B ON A.uprn = cast(B.uprn as varchar)
        LEFT JOIN Street_Rec as C ON B.usrn = C.usrn
        LEFT JOIN MC_Permit_Flag as D ON A.permit_reference = D.permit_reference
        AND A.VRM = D.vrm
    WHERE A.import_date = format_datetime(current_date, 'yyyyMMdd')
        AND current_date between start_date and end_date
        AND Permit_type IN (
            'Business',
            'Residents',
            'Companion Badge',
            'Estate Resident'
        )
        AND latest_permit_status not IN ('Cancelled', 'Rejected', 'RENEW_REJECTED')
),
Permits_summ as (
    SELECT permit_type,
        cpz,
        address2 as Street,
        cast(count(*) as int) as CurrentPermitTotal
    FROM Permits
    WHERE r1 = 1
        AND is_motorcycle != 'Y'
    GROUP BY permit_type,
        cpz,
        address2
    UNION ALL
    SELECT 'Motorcycle',
        cpz,
        address2 as Street,
        cast(count(*) as int) as CurrentPermitTotal
    FROM Permits
    WHERE r1 = 1
        AND is_motorcycle = 'Y'
    GROUP BY cpz,
        address2
),
CPZ_List as (
    SELECT DISTINCT upper(cpz) as cpz,
        upper(Street) as Street
    FROM Permits_summ
    UNION ALL
    SELECT distinct UPPER(REPLACE(Zone, 'Zone ', '')),
        upper(street_name)
    FROM Parkmap_Summary
),
CPZ_List_DeDupe as (
    SELECT cpz,
        Street,
        ROW_NUMBER() OVER (
            PARTITION BY cpz,
            Street
            ORDER BY cpz,
                Street DESC
        ) CPZ1
    FROM CPZ_List
),
/** collate & Output the data **/
Output as (
    SELECT Distinct A.cpz,
        A.Street,
        B.CurrentPermitTotal as Total_Residential_Permits,
        C.currentPermitTotal as Total_Estate_Residential_Permits,
        D.currentPermitTotal as Total_Business_Permits,
        E.currentPermitTotal as Total_Companion_Badge_Permits,
        L.currentPermitTotal as Total_Motorcycle_Permits,
        /****/
        F.no_of_spaces as Business_bay_no_of_spaces,
        G.no_of_spaces as Shared_Use_no_of_spaces,
        H.no_of_spaces as Permit_Bay_no_of_spaces,
        I.no_of_spaces as Resident_bay_no_of_spaces,
        K.no_of_spaces as Estate_bay_no_of_spaces,
        J.no_of_spaces as Disabled_bay_no_of_spaces,
        M.no_of_spaces as Motorcycle_bay_no_of_spaces,
        /****/
        (
            coalesce(B.currentPermitTotal, 0) + coalesce(C.currentPermitTotal, 0) + coalesce(D.currentPermitTotal, 0) + coalesce(E.currentPermitTotal, 0) + coalesce(L.currentPermitTotal, 0)
        ) as TotalNoofPermits,
        (
            coalesce(F.no_of_spaces, 0) + coalesce(G.no_of_spaces, 0) + coalesce(H.no_of_spaces, 0) + coalesce(I.no_of_spaces, 0) + coalesce(J.no_of_spaces, 0) + coalesce(K.no_of_spaces, 0) + coalesce(M.no_of_spaces, 0)
        ) as TotalNoOfSpaces
    FROM CPZ_List_DeDupe as A
        LEFT JOIN Permits_summ as B ON A.cpz = B.cpz
        AND lower(A.Street) = lower(B.Street)
        AND B.permit_type = 'Residents'
        LEFT JOIN Permits_summ as C ON A.cpz = C.cpz
        AND lower(A.Street) = lower(C.Street)
        AND C.permit_type = 'Estate Resident'
        LEFT JOIN Permits_summ as D ON A.cpz = D.cpz
        AND lower(A.Street) = lower(C.Street)
        AND D.permit_type = 'Business'
        LEFT JOIN Permits_summ as E ON A.cpz = E.cpz
        AND lower(A.Street) = lower(E.Street)
        AND E.permit_type = 'Companion Badge'
        /*****/
        LEFT JOIN Parkmap_Summary as F ON A.cpz = F.zone
        AND lower(A.Street) = lower(F.street_name)
        AND F.order_type = 'Business bay'
        LEFT JOIN Parkmap_Summary as G ON A.cpz = G.zone
        AND lower(A.Street) = lower(G.street_name)
        AND G.order_type = 'Shared Use'
        LEFT JOIN Parkmap_Summary as H ON A.cpz = H.zone
        AND lower(A.Street) = lower(H.street_name)
        AND H.order_type = 'Permit Bay'
        LEFT JOIN Parkmap_Summary as I ON A.cpz = I.zone
        AND lower(A.Street) = lower(I.street_name)
        AND I.order_type = 'Resident bay'
        LEFT JOIN Parkmap_Summary as K ON A.cpz = K.zone
        AND lower(A.Street) = lower(K.street_name)
        AND K.order_type = 'Estate permit bay'
        LEFT JOIN Parkmap_Summary as J ON A.cpz = J.zone
        AND lower(A.Street) = lower(J.street_name)
        AND J.order_type = 'Disabled'
        /** M/C Bays / Permits **/
        LEFT JOIN Permits_summ as L ON A.cpz = L.cpz
        AND lower(A.Street) = lower(L.Street)
        AND L.permit_type = 'Motorcycle'
        LEFT JOIN Parkmap_Summary as M ON A.cpz = M.zone
        AND lower(A.Street) = lower(M.street_name)
        AND M.order_type = 'Motorcycle Bay'
    WHERE CPZ1 = 1 -- ORDER BY A.cpz, A.Street
)
/** Output the report **/
SELECT *,
    case
        When TotalNoOfSpaces > 0 Then cast(TotalNoofPermits as decimal(10, 4)) / TotalNoOfSpaces
        else -1
    END as PercentageStress,

    format_datetime(current_date, 'yyyy') AS import_year,
    format_datetime(current_date, 'MM') AS import_month,
    format_datetime(current_date, 'dd') AS import_day,
    format_datetime(current_date, 'yyyyMMdd') AS import_date
FROM Output
WHERE length(trim(cpz)) != 0
    AND length(trim(Street)) != 0
"""

create_update_table_with_partition(
    environment=environment, query_on_athena=query_on_athena, table_name=table_name
)
