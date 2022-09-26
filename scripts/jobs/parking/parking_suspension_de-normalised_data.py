import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

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
AmazonS3_node1627053246341 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_suspension_change",
    transformation_ctx="AmazonS3_node1627053246341",
)

# Script generated for node Amazon S3
AmazonS3_node1627053109317 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_activity",
    transformation_ctx="AmazonS3_node1627053109317",
)

# Script generated for node Amazon S3
AmazonS3_node1627053334221 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_suspension",
    transformation_ctx="AmazonS3_node1627053334221",
)

# Script generated for node Amazon S3
AmazonS3_node1625732651466 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_permit_status",
    transformation_ctx="AmazonS3_node1625732651466",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*************************************************************************************************************************
SuspensionDeNormalisation

The SQL denormalises the Suspension data into a SINGLE row for each of the Suspension requests

19/07/2021 - Create SQL
20/08/2021 - changed because I did not have an HYS filter?
26/09/2022 - Add an additional check for ONLY suspensions
*************************************************************************************************************************/

/************************************************************************************************************************
Get the LATEST Suspension status
*************************************************************************************************************************/
WITH SuspensionStatus as (
SELECT 
   permit_referece, 
   CAST(status_date as Timestamp) as status_date, 
   status, 
   status_change_by,
   ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) row_num
FROM liberator_permit_status
WHERE permit_referece like 'HYS%' AND 
      import_Date = (Select MAX(import_date) from liberator_permit_status)),
      
-- Get the various status
SusStatusCreated as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Created'),

SusStatusReceived as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Received'),

SusStatusExtnReq as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Extension Requested'),

SusStatusNotRecd as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Not-Received'),

SusStatusExtnApp as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Extension Approved'),

SusStatusExtnRej as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Extension Rejected'),

SusStatusSignUp as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Sign up'),

SusStatusAppRej as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Approved' OR status = 'Rejected'),

SusStatusCancelled as (
SELECT *, ROW_NUMBER() OVER ( PARTITION BY permit_referece ORDER BY permit_referece, status_date DESC) RNum
FROM SuspensionStatus
WHERE status = 'Cancelled'),
      
/***************************************************************************************************************************************
Obtain the latest suspension approval records
****************************************************************************************************************************************/ SusApprovalPre as (     

SELECT permit_referece                    as PermitReference,
       CAST(status_date as timestamp)     as ApprovalDate,
       status                             as Approvaltype,
       status_change_by                   as ApprovedBy

FROM SuspensionStatus
WHERE Status LIKE '%Approved%' OR Status LIKE '%Rejected%'
UNION ALL
SELECT permit_referece,  
       CAST(activity_date as timestamp), 
       'Additional evidence requested',
       activity_by
FROM liberator_permit_activity as A
WHERE import_Date = (Select MAX(import_date) from liberator_permit_activity) AND activity like 'Additional evidence requested%'
       AND A.permit_referece like 'HYS%'),

-- Find the latest approval date
SusApproval as (
SELECT *,
       ROW_NUMBER() OVER ( PARTITION BY PermitReference ORDER BY PermitReference, ApprovalDate DESC) row_num
FROM SusApprovalPre),

/***************************************************************************************************************************************
Get the Suspension change ecords and format the dates to allow a second stage to find the latest
****************************************************************************************************************************************/
LibSusChange_Before as (           
 SELECT
   supension_reference, cast(supension_change_application_date as timestamp) as Change_App_Date, new_start_date, new_end_date,
   supension_change_amount, supension_change_payment_date, supension_change_payment_status

FROM liberator_permit_suspension_change
WHERE import_Date = (Select MAX(import_date) from liberator_permit_suspension_change)),

-- Format the data to find the very LATEST suspension change
LibSusChange as (
SELECT 
    *,
    ROW_NUMBER() OVER ( PARTITION BY supension_reference ORDER BY supension_reference, Change_App_Date DESC) row_num
FROM LibSusChange_Before),

/***************************************************************************************************************************************
Get the 'base' Suspension Data
****************************************************************************************************************************************/
LibSusData as (
SELECT suspensions_reference, 
       -- Cast the application date from string to date
       CASE When application_date = '' Then cast(NULL as timestamp)
       ELSE CAST(application_date as timestamp) END                                  as ApplicationDate, 
       forename_of_applicant, surname_of_applicant, email_address_of_applicant, 
       -- CAST The Start Date from string to date
       CASE When start_date = '' Then cast(NULL as timestamp)
       ELSE CAST(start_date as timestamp) END                                        as StartDate, 
       -- CAST The End Date from string to date
       CASE When end_date = '' Then cast(NULL as timestamp)
       ELSE CAST(end_date as timestamp) END                                          as EndDate, 
       start_time, end_time, 
        -- CAST The amount paid from string to money/decimal
       CASE When amount = '' Then cast(0 as decimal(11,2))
       ELSE CAST(amount as decimal(11,2)) END                                        as Payment,
       -- CAST The payment Date from string to date
       CASE When payment_date = '' Then cast(NULL as timestamp)
       ELSE CAST(payment_date as timestamp) END                                      as PaymentDate,
       payment_received                                                              as PaymentStatus,
       permit_type, business_name, applicant_address,
        -- CAST The number of bays from string to integer
       CASE When number_of_bays = '' Then cast(0 as int)
       ELSE CAST(number_of_bays as int) END                                          as number_of_bays,
       street_name, usrn, suspension_reason

FROM liberator_permit_suspension
WHERE import_Date = (Select MAX(import_date) from liberator_permit_suspension))

/***************************************************************************************************************************************
Combine the CTR data
****************************************************************************************************************************************/
SELECT A.*, 
       Change_App_Date,new_start_date,new_end_date,
       C.status_date                                   as LatestStatusDate,
       C.status                                        as LatestStatus,
       C.status_change_by                              as LatestStatusChangeBy,
       D.status_date                                   as Created_Date,
       E.status_date                                   as Received_Date,
       F.status_date                                   as Extension_Req_Date,
       G.status_date                                   as Not_Received_Date,
       H.status_date                                   as Extn_Approved_Date,
       I.status_date                                   as Extn_Rejected_Date,
       J.status_date                                   as Signs_Up_Date,
       K.status_date                                   as App_Reject_Date,
       K.status                                        as App_Reject_status,      
       L.status_date                                   as Cancel_Date,
       
       current_timestamp() as ImportDateTime,
    
       replace(cast(current_date() as string),'-','') as import_date,
    
       -- Add the Import date
       cast(Year(current_date) as string)  as import_year, 
       cast(month(current_date) as string) as import_month,
       cast(day(current_date) as string)   as import_day
       
FROM LibSusData as A
LEFT JOIN LibSusChange as B ON A.suspensions_reference       = B.supension_reference AND B.row_num = 1
LEFT JOIN SuspensionStatus as C ON A.suspensions_reference   = C.permit_referece     AND C.row_num = 1
LEFT JOIN SusStatusCreated as D ON A.suspensions_reference   = D.permit_referece     AND D.row_num = 1
LEFT JOIN SusStatusReceived as E ON A.suspensions_reference  = E.permit_referece     AND E.row_num = 1
LEFT JOIN SusStatusExtnReq as F ON A.suspensions_reference   = F.permit_referece     AND F.row_num = 1
LEFT JOIN SusStatusNotRecd as G ON A.suspensions_reference   = G.permit_referece     AND G.row_num = 1
LEFT JOIN SusStatusExtnApp as H ON A.suspensions_reference   = H.permit_referece     AND H.row_num = 1
LEFT JOIN SusStatusExtnRej as I ON A.suspensions_reference   = I.permit_referece     AND I.row_num = 1 
LEFT JOIN SusStatusSignUp as J ON A.suspensions_reference    = J.permit_referece     AND J.row_num = 1
LEFT JOIN SusStatusAppRej as K ON A.suspensions_reference    = K.permit_referece     AND K.row_num = 1
LEFT JOIN SusStatusCancelled as L ON A.suspensions_reference = L.permit_referece     AND L.row_num = 1
WHERE lower(permit_type) = 'suspension'
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_permit_status": AmazonS3_node1625732651466,
        "liberator_permit_activity": AmazonS3_node1627053109317,
        "liberator_permit_suspension_change": AmazonS3_node1627053246341,
        "liberator_permit_suspension": AmazonS3_node1627053334221,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Suspension_DeNormalised_Data/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Suspension_DeNormalised_Data",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
