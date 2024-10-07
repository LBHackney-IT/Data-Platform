import sys

from awsglue import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import get_glue_env_var

environment = get_glue_env_var("environment")


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

# Script generated for node Amazon S3
AmazonS3_node1625732038443 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_licence_full",
    transformation_ctx="AmazonS3_node1625732038443",
)

# Script generated for node Amazon S3
AmazonS3_node1631704526786 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_renewal",
    transformation_ctx="AmazonS3_node1631704526786",
)

# Script generated for node Amazon S3
AmazonS3_node1637693702237 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_status",
    transformation_ctx="AmazonS3_node1637693702237",
)

# Script generated for node Amazon S3
AmazonS3_node1637693786853 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_inspections",
    transformation_ctx="AmazonS3_node1637693786853",
)

# Script generated for node Amazon S3
AmazonS3_node1637693831333 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="AmazonS3_node1637693831333",
)

# Script generated for node Amazon S3
AmazonS3_node1637693886525 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_licence_payments",
    transformation_ctx="AmazonS3_node1637693886525",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/**************************************************************************************************************
Parking_Markets_Denormalisation

This query de-normalises the markets & shopfront data

23/11/2021 - create the query
****************************************************************************************************************/

/**************************************************************************************************************************
Get the Licence (Market & Shopfront) data
**************************************************************************************************************************/
With Latest_Business_Before as (
   SELECT
      unique_id, licence_ref, licence_type, licence_address, licence_uprn, red_route, application_date, created_by,
      requested_start_date, actual_start_date,
      /*** Get a possible End Date ***/
      CASE
         When licence_type IN ('SF-newperm','MARKET-renewperm') Then cast('9999-12-31' as date)
         When actual_start_date != '' Then
             CASE
                When actual_start_date like '%/%'Then
                             date_add(CAST(substr(actual_start_date, 7,4)||'-'||
                             substr(actual_start_date, 4,2)||'-'||
                             substr(actual_start_date, 1,2) as date), 364)

                ELSE cast(actual_start_date as date) END
         When requested_start_date != '' Then
             CASE
                When requested_start_date like '%/%'Then
                              date_add(CAST(substr(requested_start_date, 7,4)||'-'||
                              substr(requested_start_date, 4,2)||'-'||
                              substr(requested_start_date, 1,2) as date), 364)
                ELSE cast(requested_start_date as date) END

      END as EndDate,

      application_type, requested_width_1, requested_depth_1, requested_width_2,
      requested_depth_2, requested_width_3, requested_depth_3, actual_width_1, actual_depth_1, actual_width_2, actual_depth_2,
      actual_width_3, actual_depth_3, requested_area, actual_area, applicant_name, applicant_address, applicant_uprn,
      business_id, business_name, business_address, business_uprn, business_type, business_registration_number,
      approved_by, rejected_by,
      /*** Create a Unique_ID by stripping off first characters ***/
      CASE
         When Licence_ref like 'SF%' Then Replace(Licence_ref, 'SF')
         When Licence_Ref like 'MAR%' Then Replace (licence_ref, 'MAR')
      END as Unique_Ref,

      /*** Remove carriage return like feed ***/
      REPLACE(REPLACE(approved_notes, '\r',''), '\n','')       as approved_notes,
      REPLACE(REPLACE(reason_for_rejection, '\r',''), '\n','') as reason_for_rejection,
      REPLACE(REPLACE(rejection_notes, '\r',''), '\n','')     as rejection_notes

   FROM liberator_licence_licence_full
   WHERE import_Date = (Select MAX(import_date) from liberator_licence_licence_full)
   and business_name not in ('IvieSCSC Ltd','IvieSCSC')
   order by Business_ID, requested_start_date),

/*** Now index the END date to find the latest record for a business ***/
Latest_Business as (
    SELECT
       *,
       /*** Create a Row Number to identify the latest record ***/
       ROW_NUMBER() OVER ( PARTITION BY Business_ID
                       ORDER BY  Business_ID, EndDate DESC) row_num
     FROM Latest_Business_Before),

/**************************************************************************************************************************
Get the renewal data
**************************************************************************************************************************/
Renewal_ref as (
   SELECT
      renewal_ref,original_ref, renewal_type, renewal_date
    FROM liberator_licence_renewal
    WHERE import_Date = (Select MAX(import_date) from liberator_licence_licence_full)),

/**************************************************************************************************************************
Get the renewal data
**************************************************************************************************************************/
Status_Data as (
   SELECT
      licence_ref, status, status_start_date, status_end_date,

      /*** Create a Row Number to identify the latest record ***/
      ROW_NUMBER() OVER ( PARTITION BY licence_ref
                       ORDER BY  licence_ref, status_start_date DESC) row_num
   FROM liberator_licence_status
   WHERE import_Date = (Select MAX(import_date) from liberator_licence_status)),

/**************************************************************************************************************************
Get the inspections data
**************************************************************************************************************************/
Inspections as (
   SELECT
      licence_ref, inspection_date,
      REPLACE(REPLACE(inspection_reason, '\r',''), '\n','') as inspection_reason,
      REPLACE(REPLACE(internal_notes, '\r',''), '\n','')    as INSP_internal_notes,
      REPLACE(REPLACE(external_notes, '\r',''), '\n','')    as INSP_external_notes,
      REPLACE(REPLACE(recommendation, '\r',''), '\n','')    as INSP_recommendation,
      area_width_1 as INSP_area_width_1, area_depth_1 as INSP_area_depth_1,
      area_width_2 as INSP_area_width_2, area_depth_2 as INSP_area_depth_2,
      area_width_3 as INSP_area_width_3, area_depth_3 as INSP_area_depth_3,
      total_area as INSP_total_area, drawing as INSP_drawing,

      /*** Create a Row Number to identify the latest record ***/
      ROW_NUMBER() OVER ( PARTITION BY licence_ref
                       ORDER BY  licence_ref, inspection_date DESC) row_num

   FROM liberator_licence_inspections
   WHERE import_Date = (Select MAX(import_date) from liberator_licence_inspections)),

/**************************************************************************************************************************
Get the LLPG data
**************************************************************************************************************************/
LLPG as (
   SELECT *
   FROM liberator_permit_llpg
   WHERE import_Date = (Select MAX(import_date) from liberator_licence_inspections)),

/**************************************************************************************************************************
Get the payments
**************************************************************************************************************************/
Payments as (
   SELECT
      licence_ref, replace(licence_ref, 'LICO') as Unique_Ref,
      CASE
         When Payment_Type = 'REFUND' Then -(cast(amount as double))
         Else cast(amount as double)
      END as Amount

    FROM liberator_licence_payments
    WHERE import_date = (Select MAX(import_date) from liberator_licence_payments)),

Total_Payments as (
   SELECT
      Licence_Ref, Unique_ref, round(Sum(Amount),2) as Total_Payment
   FROM Payments
   GROUP BY Licence_Ref, Unique_ref)

/**************************************************************************************************************************
Output the data
**************************************************************************************************************************/
SELECT
   A.*,
   renewal_type, renewal_date, original_ref,
   status, status_start_date, status_end_date
   inspection_reason, INSP_internal_notes, INSP_external_notes, INSP_recommendation,
   INSP_area_width_1,INSP_area_depth_1,
   INSP_area_width_2,INSP_area_depth_2,
   INSP_area_width_3,INSP_area_depth_3,
   INSP_total_area, INSP_total_area, bplu_class, Total_Payment,

    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date
FROM Latest_Business as A
LEFT JOIN Renewal_ref    as B ON A.licence_ref = B.renewal_ref
LEFT JOIN Status_Data    as C ON A.licence_ref = C.licence_ref AND C.row_num = 1
LEFT JOIN Inspections    as D ON A.licence_ref = D.licence_ref AND D.row_num = 1
LEFT JOIN LLPG           as E ON A.licence_uprn = cast(E.uprn as string)
LEFT JOIN Total_Payments as F ON A.Unique_Ref = F.Unique_ref
WHERE A.row_num = 1
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_licence_status": AmazonS3_node1637693702237,
        "liberator_licence_licence_full": AmazonS3_node1625732038443,
        "liberator_licence_inspections": AmazonS3_node1637693786853,
        "liberator_licence_renewal": AmazonS3_node1631704526786,
        "liberator_permit_llpg": AmazonS3_node1637693831333,
        "liberator_licence_payments": AmazonS3_node1637693886525,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Markets_Denormalisation/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Markets_Denormalisation",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
