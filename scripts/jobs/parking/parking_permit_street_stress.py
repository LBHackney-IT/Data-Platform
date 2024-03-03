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
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node Amazon S3
AmazonS3_node1681807440414 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="geolive_parking_order",
    transformation_ctx="AmazonS3_node1681807440414",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node Amazon S3
AmazonS3_node1681807784480 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_permit_denormalised_data",
    transformation_ctx="AmazonS3_node1681807784480",
    push_down_predicate=create_pushdown_predicate("import_date", 1),
)

# Script generated for node SQL
SqlQuery29 = """
/***********************************************************************************
Parking_Permit_Street_Stress

The SQL builds a list of streets and identifies the number of 
Parking spaces (Shared use, Resident, etc) and the number of extant Permits

16/03/2023 - Create SQL
*********************************************************************************/
With LLPG as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from 
                                            liberator_permit_llpg)),
Street_Rec as (
    SELECT *
    FROM liberator_permit_llpg
    WHERE import_date = (Select MAX(import_date) from 
                                             liberator_permit_llpg)
    AND address1 = 'STREET RECORD'),

Parkmap as (
    SELECT
        order_type, street_name, no_of_spaces, zone, nsg
    FROM geolive_parking_order
    WHERE import_date = (Select MAX(import_date) 
                                   from geolive_parking_order)
    AND order_type IN ('Business bay', 'Estate permit bay', 'Cashless Shared Use', 'Permit Bay', 
                       'Permit Electric Vehicle', 'Resident bay',
                       'Shared Use - Permit/Chargeable','Disabled')),
Parkmap_Summary as (
    SELECT 'Business bay' as order_type, street_name, 
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type = 'Business bay'
    GROUP BY street_name
    UNION ALL
    SELECT 'Estate permit bay' as order_type, street_name, 
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type = 'Estate permit bay'
    GROUP BY street_name 
    UNION ALL
    SELECT 'Shared Use' as order_type, street_name, 
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Cashless Shared Use','Shared Use - Permit/Chargeable')
    GROUP BY street_name 
    UNION ALL
    SELECT 'Permit Bay' as order_type, street_name, 
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Permit Bay')
    GROUP BY street_name
    UNION ALL
    SELECT 'Resident bay' as order_type, street_name, 
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Resident bay')
    GROUP BY street_name
    UNION ALL
    SELECT 'Disabled' as order_type, street_name, 
    SUM(no_of_spaces) as no_of_spaces
    FROM Parkmap
    WHERE order_type IN ('Disabled')
    GROUP BY street_name    
    ),

Permits as (
    SELECT
        A.permit_reference, A.email_address_of_applicant, 
        A.permit_type, C.address2, 
        address_line_1, address_line_2, address_line_3,postcode, 
        A.uprn,
        ROW_NUMBER() OVER ( PARTITION BY A.email_address_of_applicant  
        ORDER BY A.email_address_of_applicant, A.permit_type DESC) r1
    FROM parking_permit_denormalised_data as A
    LEFT JOIN LLPG as B ON A.uprn = cast(B.uprn as string)
    LEFT JOIN Street_Rec as C ON B.usrn = C.usrn
    WHERE A.import_date = (Select MAX(import_date) from 
                                  parking_permit_denormalised_data)
    AND current_date between start_date and end_date 
    AND Permit_type IN ('Business', 'Residents','Companion Badge')
    AND latest_permit_status not IN ('Cancelled','Rejected','RENEW_REJECTED')),

Permits_summ as (
    SELECT
        permit_type, address2, cast(count(*) as int) as CurrentPermitTotal
    FROM Permits
    WHERE r1 = 1
    GROUP BY permit_type, address2
    Order by address2, permit_type),    

Output as (  
    SELECT 
        A.Address2 as Street, A.currentPermitTotal as Total_Residential_Permits,
        G.currentPermitTotal as Total_Business_Permits, 
        I.currentPermitTotal as Total_Companion_Badge_Permits, 
    
        B.no_of_spaces as Business_bay_no_of_spaces,
        D.no_of_spaces as Shared_Use_no_of_spaces,
        E.no_of_spaces as Permit_Bay_no_of_spaces,
        F.no_of_spaces as Resident_bay_no_of_spaces,    
        H.no_of_spaces as Disabled_bay_no_of_spaces,

        (coalesce(A.currentPermitTotal,0) + coalesce(G.currentPermitTotal, 0) + 
                                            coalesce(I.currentPermitTotal, 0)) as TotalNoofPermits,
        (coalesce(B.no_of_spaces,0) + coalesce(D.no_of_spaces,0) + coalesce(E.no_of_spaces,0)
                        + coalesce(F.no_of_spaces,0) + coalesce(H.no_of_spaces,0)) as TotalNoOfSpaces
    FROM Permits_summ as A
    LEFT JOIN Parkmap_Summary as B ON lower(A.address2) = lower(B.street_name) AND B.order_type = 'Business bay'
    LEFT JOIN Parkmap_Summary as C ON lower(A.address2) = lower(C.street_name) AND C.order_type = 'Estate permit bay'
    LEFT JOIN Parkmap_Summary as D ON lower(A.address2) = lower(D.street_name) AND D.order_type = 'Shared Use'
    LEFT JOIN Parkmap_Summary as E ON lower(A.address2) = lower(E.street_name) AND E.order_type = 'Permit Bay'
    LEFT JOIN Parkmap_Summary as F ON lower(A.address2) = lower(F.street_name) AND F.order_type = 'Resident bay'
    LEFT JOIN Parkmap_Summary as H ON lower(A.address2) = lower(H.street_name) AND H.order_type = 'Disabled'

    LEFT JOIN Permits_summ as G ON lower(A.address2) = lower(G.address2) AND G.permit_type = 'Business'
    LEFT JOIN Permits_summ as I ON lower(A.address2) = lower(I.address2) AND I.permit_type = 'Companion Badge'
    WHERE A.permit_type = 'Residents'
    ORDER BY A.address2)

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
    query=SqlQuery29,
    mapping={
        "liberator_permit_llpg": AmazonS3_node1658997944648,
        "geolive_parking_order": AmazonS3_node1681807440414,
        "parking_permit_denormalised_data": AmazonS3_node1681807784480,
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/parking_permit_street_stress/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=PARTITION_KEYS,
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="parking_permit_street_stress",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
