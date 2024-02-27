import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import (
    PARTITION_KEYS,
    create_pushdown_predicate_for_max_date_partition_value,
    get_glue_env_var,
    get_latest_partitions,
)


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

environment = get_glue_env_var("environment")

# Script generated for node Amazon S3
AmazonS3_node1658997944648 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="parking_parking_ops_cycle_hangar_list",
    transformation_ctx="AmazonS3_node1658997944648",
)

# Script generated for node Amazon S3
AmazonS3_node1697705005761 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="AmazonS3_node1697705005761",
)

# Script generated for node Amazon S3
AmazonS3_node1697704537304 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_cycle_hangars_denormalisation",
    transformation_ctx="AmazonS3_node1697704537304",
)

# Script generated for node Amazon S3
AmazonS3_node1697705499200 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_hangar_allocations",
    transformation_ctx="AmazonS3_node1697705499200",
)

# Script generated for node Amazon S3
AmazonS3_node1697704672904 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_hangar_waiting_list",
    transformation_ctx="AmazonS3_node1697704672904",
)

# Script generated for node Amazon S3
AmazonS3_node1697704891824 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_party",
    transformation_ctx="AmazonS3_node1697704891824",
)

# Script generated for node SQL
SqlQuery3 = """
/********************************************************************************************************************
parking_cycle_hangar_allocation

The SQL details the number of cycle spaces that are occupied
in each cycle hangar. It also identifies the number of Parties
that are on the waiting list. The code has been amended to use
Tom's hangar list

19/10/2023 - Create Query
test
*******************************************************************************************************************/
/************************************************************
Create a comparison between Toms Hangar list and EStreet
************************************************************/
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
    from parking_parking_ops_cycle_hangar_list
    WHERE import_date = (Select MAX(import_date) 
                        from parking_parking_ops_cycle_hangar_list)
    AND asset_type = 'Hangar' AND lower(status) like '%active%'),
    
Hanger as (
    SELECT hanger_id,
    ROW_NUMBER() OVER ( PARTITION BY hanger_id ORDER BY hanger_id DESC) H1
    From parking_cycle_hangars_denormalisation 
    WHERE import_date = (Select MAX(import_date) 
                    from parking_cycle_hangars_denormalisation)),

Hangar_Comp as (
    SELECT
        asset_no, HangarID, B.hanger_id
    FROM TomHangar as A
    LEFT JOIN Hanger as B ON A.HangarID = B.hanger_id AND H1 = 1
    UNION ALL 
    SELECT 'new_only','new_only','new_only'),
/************************************************************
Create the Waiting list - unique "party_id"
************************************************************/
waiting_list as (
    SELECT *,
        ROW_NUMBER() OVER ( PARTITION BY party_id, hanger_id ORDER BY party_id, hanger_id DESC) row1
    FROM liberator_hangar_waiting_list
    WHERE Import_Date = (Select MAX(Import_Date) from 
                                    liberator_hangar_waiting_list)),
/*** Party List ***/
Licence_Party as (
    SELECT * from liberator_licence_party 
    WHERE Import_Date = (Select MAX(Import_Date) from 
                                        liberator_licence_party)),
/*** STREET ***/
LLPG as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from 
                                        liberator_permit_llpg)),
/*******************************************************************************
Cycle Hangar allocation details
*******************************************************************************/ 
Cycle_Hangar_allocation as (
    SELECT 
        *,
        ROW_NUMBER() OVER ( PARTITION BY party_id
        ORDER BY party_id, date_of_allocation DESC) row_num
    FROM liberator_hangar_allocations
    WHERE Import_Date = (Select MAX(Import_Date) from 
                                liberator_hangar_allocations)
    AND allocation_status IN ('live')),
    
Street_Rec as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from 
                                            liberator_permit_llpg)
    AND address1 = 'STREET RECORD'),
    
Cycle_Hangar_Wait_List as (
    SELECT
        A.party_id, first_name, surname, B.uprn as USER_UPRN,
        B.address1, B.address2, B.address3, B.postcode, B.telephone_number, D.Address2 as Street,registration_date
        ,A.hanger_id, E.party_id Allocated_Party_ID
    FROM waiting_list as A
    LEFT JOIN Licence_Party as B ON A.party_id = B.business_party_id
    LEFT JOIN LLPG          as C ON B.uprn = cast(C.UPRN as string)
    LEFT JOIN Street_Rec    as D ON C.USRN = D.USRN
    LEFT JOIN Cycle_Hangar_allocation as E ON A.party_id = E.party_id  AND row_num = 1
    WHERE row1= 1 AND E.party_id is NULL and D.Address2 is not NULL),

/************************************************************
Waiting List CREATED
************************************************************/
Estreet_Hanger as (
    SELECT hanger_id, space, hangar_location,
    ROW_NUMBER() OVER ( PARTITION BY hanger_id, space, hangar_location 
                                    ORDER BY hanger_id, space, hangar_location DESC) H1
    From parking_cycle_hangars_denormalisation 
    WHERE import_date = (Select MAX(import_date) from parking_cycle_hangars_denormalisation) and
    allocation_status = 'live' and key_issued = 'Y'
    UNION ALL 
    SELECT 'new_only', ' ', 'NEWONLY', 1),

Wait_List_Hangar as (
    SELECT A.party_id, A.hanger_id,
    ROW_NUMBER() OVER ( PARTITION BY A.party_id, A.hanger_id 
                                    ORDER BY A.party_id, A.hanger_id DESC) H2
    FROM liberator_hangar_waiting_list as A
    INNER JOIN Cycle_Hangar_Wait_List as B ON A.party_id = B.party_id
    WHERE import_date = (Select MAX(import_date) 
                            FROM liberator_hangar_waiting_list)),

Wait_List_Earlist_Latest as (
    SELECT A.hanger_id, max(A.registration_date) as Max_Date, min(A.registration_date) as Min_Date
    FROM liberator_hangar_waiting_list as A
    INNER JOIN Cycle_Hangar_Wait_List as B ON A.party_id = B.party_id
    WHERE import_date = (Select MAX(import_date) 
                                FROM liberator_hangar_waiting_list)
    AND A.registration_date not 
            IN ('2000-01-01','1900-12-13','1000-04-02','1100-04-02',
                                '1200-04-02','1300-04-02','1400-04-02','2000-12-17','1200-03-24')
    GROUP BY A.hanger_id),

Wait_total as (
    SELECT hanger_id, count(*) as Wait_Total
    FROM Wait_List_Hangar
    WHERE H2 = 1
    GROUP BY hanger_id),

allocated_Total as (
    SELECT hanger_id, hangar_location, count(*) as Total_Allocated
    FROM Estreet_Hanger
    WHERE H1 = 1
    GROUP BY hanger_id,hangar_location),

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

Hangar_WAit_List as (
    SELECT 
        A.asset_no as Tom_Asset_No, B.hanger_id as HangarID, street_or_estate, zone, location_description, 
        postcode, date_installed,
        CASE
            When Total_Allocated is NULL Then 0
            ELSE Total_Allocated
        END as Total_Allocated,
        CASE
            When Wait_Total is NULL Then 0
            ELSE Wait_Total
        END as Wait_Total,
        CASE
            When free_spaces is NULL Then 6  
            ELSE free_spaces
        END as free_spaces,
    Earlist_Registration_Date, Latest_Registration_Date
    FROM TomHangar as A
    LEFT JOIN Hangar_Comp       as B ON A.asset_no = B.asset_no
    LEFT JOIN Full_Hangar_Data  as C ON B.hanger_id = C.hanger_id),

/*** Output the data ***/
Output as (
SELECT *,
    CASE 
        When Total_Allocated = 6        Then 'N/A'
        When Wait_Total >= free_spaces  Then 'Yes'
        Else 'No'
    END as hangar_can_be_filled
FROM Hangar_WAit_List
WHERE HangarID is not NULL
UNION ALL
SELECT A.Tom_Asset_No, A.HangarID, A.street_or_estate, A.zone, A.location_description,
       A.postcode, A.date_installed, A.Total_Allocated, TotalWatch, A.free_spaces,
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
        When hangar_can_be_filled = 'No' Then free_spaces - Wait_Total
        Else 0 
    END as Spaces_that_cannot_be_allocated,
    
    current_timestamp()                            as ImportDateTime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    cast(Year(current_date) as string)    as import_year, 
    cast(month(current_date) as string)   as import_month, 
    cast(day(current_date) as string)     as import_day
FROM Output
"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery3,
    mapping={
        "parking_parking_ops_cycle_hangar_list": AmazonS3_node1658997944648,
        "parking_cycle_hangars_denormalisation": AmazonS3_node1697704537304,
        "liberator_hangar_waiting_list": AmazonS3_node1697704672904,
        "liberator_licence_party": AmazonS3_node1697704891824,
        "liberator_permit_llpg": AmazonS3_node1697705005761,
        "liberator_hangar_allocations": AmazonS3_node1697705499200,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/cyclehangarallocationwaitlist/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="cyclehangarallocationwaitlist",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
