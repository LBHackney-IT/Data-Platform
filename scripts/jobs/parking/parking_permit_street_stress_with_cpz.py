import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import (
    get_glue_env_var,
    get_latest_partitions,
    PARTITION_KEYS,
    create_pushdown_predicate_for_max_date_partition_value,
    create_pushdown_predicate,
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
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="AmazonS3_node1658997944648",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node Amazon S3
AmazonS3_node1681807440414 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="geolive_parking_order",
    transformation_ctx="AmazonS3_node1681807440414",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node Amazon S3
AmazonS3_node1681807784480 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_permit_denormalised_data",
    transformation_ctx="AmazonS3_node1681807784480",
    #teporarily removed while table partitions are fixed
    #push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node SQL
SqlQuery303 = """
/***********************************************************************************
Parking_Permit_Street_Stress_With_cpz

The SQL builds a list of streets and identifies the number of 
Parking spaces (Shared use, Resident, etc) and the number of extant Permits

16/03/2023 - Create SQL
01/08/2023 - rewrite to obtain the CPZ
15/08/2023 - change because Zone does not exist in the Parkmap data
12/07/2024 - add permit reference to the Permits filter 
*********************************************************************************/
/** Get all of the addresses in HAckney **/
With LLPG as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from 
                                            liberator_permit_llpg)),
/** Get the Street records from the LLPG **/
Street_Rec as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from 
                                             liberator_permit_llpg)
    AND address1 = 'STREET RECORD'),

/** Collate the first two queries 'address' & 'Street' into one **/
LLPG_FULL as (
    SELECT
        A.address1, A.address2, A.address3, A.address4, 
        A.address5, A.post_code, 
        A.cpz_name, A.uprn, A.usrn, B.address2 as Street,
        ROW_NUMBER() OVER ( PARTITION BY A.usrn, B.address2 
                                ORDER BY A.usrn, B.address2 DESC) llpg1    
    FROM LLPG as A
    LEFT JOIN Street_Rec as B ON A.USRN = B.USRN
    WHERE A.address1 != 'STREET RECORD'),
/********************************************************************************/
/** Get the Parkmap records **/
Parkmap as (
    SELECT
        order_type, street_name, no_of_spaces, nsg, cpz_name as Zone
    FROM geolive_parking_order  as A
    LEFT JOIN LLPG_FULL as B ON lower(A.street_name) = lower(B.Street) and B.llpg1 = 1
    WHERE import_date = (Select MAX(import_date) 
                                   from geolive_parking_order)
    AND order_type IN ('Business bay', 'Estate permit bay', 'Cashless Shared Use', 'Permit Bay', 
                       'Permit Electric Vehicle', 'Resident bay',
                       'Shared Use - Permit/Chargeable','Disabled')),
/** Summerise the Parkmap records **/
Parkmap_Summary as (
    SELECT 'Business bay' as order_type, street_name, zone,
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type = 'Business bay'
    GROUP BY street_name, zone
    UNION ALL
    SELECT 'Estate permit bay' as order_type, street_name, zone,
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type = 'Estate permit bay'
    GROUP BY street_name , zone
    UNION ALL
    SELECT 'Shared Use' as order_type, street_name, zone,
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Cashless Shared Use','Shared Use - Permit/Chargeable')
    GROUP BY street_name , zone
    UNION ALL
    SELECT 'Permit Bay' as order_type, street_name, zone,
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Permit Bay')
    GROUP BY street_name , zone
    UNION ALL
    SELECT 'Resident bay' as order_type, street_name, zone,
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Resident bay')
    GROUP BY street_name , zone
    UNION ALL
    SELECT 'Disabled' as order_type, street_name, zone,
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Disabled')
    GROUP BY street_name, zone ),
/********************************************************************************/
/** Get the Permits records link in the LLPG data **/
Permits as (
    SELECT
        A.permit_reference, A.email_address_of_applicant, 
        A.permit_type, A.uprn,
        A.address_line_1, A.address_line_2, A.address_line_3, 
        A.postcode, A.cpz, A.cpz_name,
        B.usrn, B.Street,
        ROW_NUMBER() OVER ( PARTITION BY A.email_address_of_applicant, permit_reference  
                                ORDER BY A.email_address_of_applicant, A.permit_type DESC) r1
    FROM parking_permit_denormalised_data as A
    LEFT JOIN LLPG_FULL as B ON A.uprn = cast(B.uprn as string)
    WHERE A.import_date = (Select MAX(import_date) 
                             from parking_permit_denormalised_data)
    AND current_date between start_date and end_date 
    AND Permit_type IN ('Business', 'Residents','Companion Badge','Estate Resident')
    AND latest_permit_status not IN ('Cancelled','Rejected','RENEW_REJECTED')),

Permits_summ as (
    SELECT
        permit_type, cpz_name, Street, 
        cast(count(*) as int) as CurrentPermitTotal
    FROM Permits
    WHERE r1 = 1
    GROUP BY permit_type, cpz_name, Street
    Order by Street, cpz_name, permit_type),

/* Get the definative list of Streets & Zones */
Street_Zone as (
    SELECT Street, cpz_name,
            ROW_NUMBER() OVER ( PARTITION BY Street, cpz_name  
                                ORDER BY Street, cpz_name DESC) r2
    FROM Permits_summ),
/********************************************************************************/
/** collate & Output the data **/
Output as ( 
    SELECT 
        A.Street, A.cpz_name as CPZ,
        K.currentPermitTotal as Total_Residential_Permits,
        J.currentPermitTotal as Total_Estate_Residential_Permits,
        G.currentPermitTotal as Total_Business_Permits, 
        I.currentPermitTotal as Total_Companion_Badge_Permits, 

        B.no_of_spaces as Business_bay_no_of_spaces,
        D.no_of_spaces as Shared_Use_no_of_spaces,
        E.no_of_spaces as Permit_Bay_no_of_spaces,
        F.no_of_spaces as Resident_bay_no_of_spaces,
        C.no_of_spaces as Estate_bay_no_of_spaces,  
        H.no_of_spaces as Disabled_bay_no_of_spaces,

        (coalesce(K.currentPermitTotal,0) + coalesce(G.currentPermitTotal, 0) + 
                                            coalesce(I.currentPermitTotal, 0)) as TotalNoofPermits,
        (coalesce(B.no_of_spaces,0) + coalesce(D.no_of_spaces,0) + coalesce(E.no_of_spaces,0)
                        + coalesce(F.no_of_spaces,0) + coalesce(H.no_of_spaces,0)) as TotalNoOfSpaces

    FROM Street_Zone as A
    LEFT JOIN Parkmap_Summary as B ON lower(A.Street) = lower(B.street_name) 
                                AND A.cpz_name = B.zone AND B.order_type = 'Business bay'
    LEFT JOIN Parkmap_Summary as C ON lower(A.Street) = lower(C.street_name) 
                                AND A.cpz_name = C.zone AND C.order_type = 'Estate permit bay'
    LEFT JOIN Parkmap_Summary as D ON lower(A.Street) = lower(D.street_name) 
                                AND A.cpz_name = D.zone AND D.order_type = 'Shared Use'
    LEFT JOIN Parkmap_Summary as E ON lower(A.Street) = lower(E.street_name) 
                                AND A.cpz_name = E.zone AND E.order_type = 'Permit Bay'
    LEFT JOIN Parkmap_Summary as F ON lower(A.Street) = lower(F.street_name) 
                                AND A.cpz_name = F.zone AND F.order_type = 'Resident bay'
    LEFT JOIN Parkmap_Summary as H ON lower(A.Street) = lower(H.street_name) 
                                AND A.cpz_name = H.zone AND H.order_type = 'Disabled'
    /********/
    LEFT JOIN Permits_summ as G ON lower(A.Street) = lower(G.Street) 
                                AND A.cpz_name = G.cpz_name AND G.permit_type = 'Business'
    LEFT JOIN Permits_summ as I ON lower(A.Street) = lower(I.Street) 
                                AND A.cpz_name = I.cpz_name AND I.permit_type = 'Companion Badge'
    LEFT JOIN Permits_summ as J ON lower(A.Street) = lower(J.Street) 
                                AND A.cpz_name = J.cpz_name AND J.permit_type = 'Estate Resident'
    LEFT JOIN Permits_summ as K ON lower(A.Street) = lower(K.Street) 
                                AND A.cpz_name = K.cpz_name AND K.permit_type = 'Residents'
    WHERE r2 = 1
    order by A.Street, A.cpz_name)
    
/** Output the report **/
SELECT
    *, case
        When TotalNoOfSpaces > 0 Then
            cast(TotalNoofPermits as decimal(10,4))/TotalNoOfSpaces
        else -1
       END as PercentageStress,
       
    current_timestamp()                            as ImportDateTime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    cast(Year(current_date) as string)    as import_year, 
    cast(month(current_date) as string)   as import_month, 
    cast(day(current_date) as string)     as import_day
FROM Output
"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery303,
    mapping={
        "liberator_permit_llpg": AmazonS3_node1658997944648,
        "geolive_parking_order": AmazonS3_node1681807440414,
        "parking_permit_denormalised_data": AmazonS3_node1681807784480,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_permit_street_stress_with_cpz/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_permit_street_stress_with_cpz",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
