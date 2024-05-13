import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, create_pushdown_predicate
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
AmazonS3_node1628163161728 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_renewals",
    transformation_ctx="AmazonS3_node1628163161728",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1627053109317 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_fta",
    transformation_ctx="AmazonS3_node1627053109317",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1628163307688 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_vrm",
    transformation_ctx="AmazonS3_node1628163307688",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1632754989503 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1632754989503",
)

# Script generated for node Amazon S3
AmazonS3_node1628163374473 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_vrm_update",
    transformation_ctx="AmazonS3_node1628163374473",
)

# Script generated for node Amazon S3
AmazonS3_node1628173244776 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_address_update",
    transformation_ctx="AmazonS3_node1628173244776",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1628163229600 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_approval",
    transformation_ctx="AmazonS3_node1628163229600",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1634550538215 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-"+environment+"-liberator-raw-zone",
    table_name="liberator_permit_llpg",
    transformation_ctx="AmazonS3_node1634550538215",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/**************************************************************************************************************
Permits De-normalisation

This query outputs a de-normalised Permits data

03/08/2021 - create the query
23/08/2021 - Update code for Approvals/address/etc.
18/10/2021 - Add the USRN from the Permit LLPG table
25/11/2021 - debug as this code no longer works (rework Calendar)
08/05/2024 - change de-dupe of calendar
****************************************************************************************************************/
/*** Obtain the Permits start/finish for FTA and renewals ***/
With PermitStartFinishBEFORE as (
  SELECT permit_reference, 
         cast(application_date as timestamp)      as application_date, 
         cast(substr(start_date, 1, 10) as date)  as start_date,
         cast(substr(end_date, 1, 10) as date)    as end_date
  
  FROM liberator_permit_fta
  where import_Date = (Select MAX(import_date) from liberator_permit_fta) AND 
        permit_reference not like 'HYV%' AND permit_reference not like 'HYS%' AND permit_reference not like 'HYQ%' AND
        permit_reference not like 'HYF%' AND permit_reference not like 'HYJ%' AND permit_reference not like 'HYE%' AND
        (start_date != '' OR end_date != '') AND Permit_reference not like '%BWSCO%'
  UNION ALL
  SELECT permit_reference,
         cast(renewal_application_date as timestamp) as renewal_application_date, 
         cast(substr(renewal_start_date, 1, 10) as date),
         cast(substr(renewal_end_date, 1, 10) as date)
  
  FROM liberator_permit_renewals
  where import_Date = (Select MAX(import_date) from liberator_permit_renewals) AND 
        permit_reference not like 'HYV%' AND permit_reference not like 'HYS%' AND permit_reference not like 'HYQ%' AND
        permit_reference not like 'HYF%' AND permit_reference not like 'HYJ%' AND permit_reference not like 'HYE%' AND
        (renewal_start_date != '' OR renewal_end_date != '')),


-- Index the data to identify the duplicates
PermitStartFinish as (
  SELECT
     permit_reference, application_date,start_date,end_date,
     ROW_NUMBER() OVER (PARTITION BY permit_reference, application_date
                             ORDER BY permit_reference, application_date DESC) as row_num
FROM PermitStartFinishBEFORE),
/***************************************************************************************************************/
Before_CalendarFormat as (
   SELECT
      CAST(CASE
         When date like '%/%'Then substr(date, 7, 4)||'-'||substr(date, 4,2)||'-'||substr(date, 1,2)
         ELSE substr(date, 1, 10)
      end as date) as date,  
      workingday,
      holiday,
      dow,
      fin_year,
      fin_year_startdate,
      fin_year_enddate,
      import_date
   FROM calendar),
   
/*** 08/05/2024 change to de-dupe the dates fully ***/
CalendarFormat as (
    Select *,
          ROW_NUMBER() OVER ( PARTITION BY date 
                       ORDER BY  date, import_date DESC) row_num
    FROM Before_CalendarFormat),

CalendarMAX as (
   Select MAX(fin_year) as Max_Fin_Year 
   FROM CalendarFormat),

/***************************************************************************************************************/
LLPG_USRN As (
   SELECT uprn, usrn
   FROM liberator_permit_llpg 
   WHERE import_Date = (Select MAX(import_date) from liberator_permit_llpg)),
   
/***************************************************************************************************************/
/*** Select the Permit approvals ***/
PermitApprovalBefore as (
   SELECT A.permit_reference, 
          cast(approval_date as timestamp) as approval_date, 
          approved_by, 
          approval_type,
          ROW_NUMBER() OVER (PARTITION BY A.permit_reference, CAST(substr(approval_date, 1, 10) as date)
                             ORDER BY A.permit_reference, CAST(substr(approval_date, 1, 10) as date) DESC) as R1
   
FROM liberator_permit_approval as A
WHERE import_Date = (Select MAX(import_date) from liberator_permit_approval) and approval_type IN ('Approved','Rejected','Renewal')),

PermitApprovalinter as (
  SELECT A.permit_reference, approval_date,approved_by,approval_type,application_date,start_date,end_date,
         /*** Index to Find the duplicates ***/
         ROW_NUMBER() OVER (PARTITION BY A.permit_reference, cast(approval_date as date)
                             ORDER BY A.permit_reference, approval_date, application_date DESC) as Rn  
  FROM PermitApprovalBefore as A
  LEFT JOIN PermitStartFinish as B ON A.permit_reference = B.permit_reference AND
               CAST(approval_date as date) between cast(application_date as date) AND cast(end_date as date)
               AND B.row_num = 1 and R1 = 1),
         
PermitApproval as (
  SELECT permit_reference, approval_date,approved_by,approval_type,application_date,start_date,end_date,
         /*** Index to Find the duplicates ***/
         ROW_NUMBER() OVER (PARTITION BY permit_reference, application_date
                             ORDER BY permit_reference,application_date) as Rn1
  FROM PermitApprovalinter 
  WHERE Rn = 1),

/***************************************************************************************************************/
/*** Get the VRN updates and then try to link to a Permit instance ***/
VRMDetails as (
   SELECT permit_reference, 
          vrm, make, model, fuel, engine_capactiy, co2_emission, foreign, lpg_conversion,record_created,
           ROW_NUMBER() OVER (PARTITION BY permit_reference, vrm
                  ORDER BY permit_reference, vrm, co2_emission DESC) as row_num
   FROM liberator_permit_vrm
   WHERE import_Date = (Select MAX(import_date) from liberator_permit_vrm) AND vrm != ''),


VRMUpdateBefore as (
   SELECT permit_reference, 
          new_vrm,
          CASE
             When new_vrm_effective_from = '0000-00-00 00:00:00' Then cast(record_created as date)
             When cast(substr(new_vrm_effective_from, 1, 10) as date) is NULL Then cast(record_created as date)
             ELSE cast(substr(new_vrm_effective_from, 1,10) as date) 
          END as new_vrm_effective_from
           
   FROM liberator_permit_vrm_update
   WHERE import_Date = (Select MAX(import_date) from liberator_permit_vrm_update)),

VRMUpdate as (
   SELECT A.permit_reference, 
          new_vrm,
          new_vrm_effective_from,
          B.application_date              as Permit_application_date,
          ROW_NUMBER() OVER (PARTITION BY A.permit_reference, B.application_date
                  ORDER BY A.permit_reference, B.application_date, new_vrm_effective_from DESC) as row_num
  
   FROM VRMUpdateBefore as A
   LEFT JOIN PermitStartFinish as B ON A.permit_reference = B.permit_reference AND 
                                  new_vrm_effective_from between start_date AND end_date and row_num = 1),

/*** Because Persto SQL and Spark SQL is not effective enough....Get the very latest VRM against Permt *********/
VRMLatest as (
   SELECT permit_reference, 
          new_vrm,
          new_vrm_effective_from,
  
          ROW_NUMBER() OVER (PARTITION BY permit_reference
                  ORDER BY permit_reference, new_vrm_effective_from DESC) as row_num  
  
   FROM VRMUpdate
   WHERE row_num = 1),
             
/***************************************************************************************************************/
/*** Get the Address Updates ***/
AddressUpdateBefore as (
   SELECT
      A.permit_reference, 
      CAST(substr(new_address_effective_from,1, 10) as date) as new_address_effective_from, 
      new_uprn, new_address_line_1, new_address_line_2, new_address_line_3,new_postcode, 
      new_cpz, new_cpz_name,
  
      start_date, end_date,application_date,

      ROW_NUMBER() OVER (PARTITION BY A.permit_reference, CAST(substr(new_address_effective_from,1, 10) as date)
           ORDER BY A.permit_reference, CAST(substr(address_change_order_date,1, 10) as timestamp) DESC) as row_num
    
   FROM liberator_permit_address_update as A
  
   LEFT JOIN PermitStartFinish as B ON A.permit_reference = B.permit_reference AND
               CAST(substr(new_address_effective_from,1, 10) as date) between application_date AND end_date AND row_num = 1  
   
  WHERE import_Date = (Select MAX(import_date) from liberator_permit_address_update) AND
         new_address_effective_from != ''),

/*** Capture the address updates to the same permit instance ***/
AddressUpdate as (
  SELECT permit_reference, new_address_effective_from, new_uprn,new_address_line_1, new_address_line_2, new_address_line_3,
         new_postcode, new_cpz, new_cpz_name, start_date, end_date, application_date,
         
         ROW_NUMBER() OVER (PARTITION BY permit_reference, application_date
                             ORDER BY permit_reference, application_date, new_address_effective_from DESC) as row_num
  
  FROM AddressUpdateBefore
  WHERE row_num = 1),

/***************************************************************************************************************/
/*** Get the Address Updates ***/
Permit_FTA as 
(Select *
 FROM liberator_permit_fta as A
 WHERE A.import_Date = (Select MAX(import_date) from liberator_permit_fta) AND 
      A.permit_reference not like 'HYV%' AND A.permit_reference not like 'HYS%' AND A.permit_reference not like 'HYQ%' AND
      A.permit_reference not like 'HYF%' AND A.permit_reference not like 'HYJ%' AND A.permit_reference not like 'HYE%' AND
      (A.start_date != '' OR A.end_date != '') and 
      (email_address_of_applicant != 'Liberator.Testers@Hackney.gov.uk' OR surname_of_applicant != 'Tester' OR
       surname_of_applicant != 'Test')),


/**************************************************************************************************************************************/
/*** Change this to a CTE so I can add the vehicle details later **/
Permits as (
SELECT
      A.permit_reference,
      cast(A.application_date as timestamp)      as application_date,
      /*** Applicant details ***/
      forename_of_applicant,surname_of_applicant,
      email_address_of_applicant,
      primary_phone,secondary_phone,
      date_of_birth_of_applicant, 
      /*** Blue Badge details ***/
      blue_badge_number, blue_badge_expiry ,
      /*** start/finish Dates ***/
      cast(substr(A.start_date, 1, 10) as date)  as start_date,
      cast(substr(A.end_date, 1, 10) as date)    as end_date,
      /*** Approval Details ***/
      B.approval_date, B.approved_by, B.approval_type,     
      
      /*** Payment Details ***/
      amount, payment_date, payment_method, payment_location, payment_by, payment_received,
      /*** Hackney internal ***/
      directorate_to_be_charged, authorising_officer, cost_code, subjective_code,
   
      permit_type, ordered_by,
      /*** Business, etc. ***/
      business_name, hasc_organisation_name, doctors_surgery_name,
      /*** Bays, dispensation ***/
      number_of_bays, number_of_days, number_of_dispensation_vehicles, dispensation_reason,
      /*** Address / UPRN ***/
      CASE -- UPRN
         When new_address_effective_from is not NULL Then new_uprn
         ELSE uprn
      END as uprn,
      CASE  -- Address Line 1
         When new_address_effective_from is not NULL Then new_address_line_1
         ELSE address_line_1
      END as address_line_1,       
      CASE  -- Address Line 2
         When new_address_effective_from is not NULL Then new_address_line_2
         ELSE address_line_2
      END as address_line_2,          
      CASE  -- Address Line 3
         When new_address_effective_from is not NULL Then new_address_line_3
         ELSE address_line_3
      END as address_line_3,  
      CASE  -- Postcode
         When new_address_effective_from is not NULL Then new_postcode
         ELSE postcode
      END as postcode,                   
      /*** Zone ***/
      CASE  -- CPZ
         When new_address_effective_from is not NULL Then new_cpz
         ELSE cpz
      END as cpz,        
      CASE  -- CPZ Name
         When new_address_effective_from is not NULL Then new_cpz_name
         ELSE cpz_name
      END as cpz_name,
      /*** Vehicle ***/
      status, quantity,
      CASE
         When D.new_vrm is not NULL Then D.new_vrm
         ELSE vrm
      END as vrm, 
      associated_to_order,
      /*** Flags ***/
      CASE
         When current_date between cast(substr(A.start_date, 1, 10) as date) AND
                                                  cast(substr(A.end_date, 1, 10) as date) Then 1
         ELSE 0 
      END                                                 as Live_Permit_Flag,
      0                                                   as Permit_Fta_Renewal,
      Status                                              as Latest_Permit_Status,
      /*** Try and trap problems with the data ***/
      ROW_NUMBER() OVER ( PARTITION BY A.permit_reference, A.start_date, A.end_date
                                                          ORDER BY A.permit_reference, A.application_date DESC) as Rn 
FROM Permit_FTA as A
LEFT JOIN PermitApproval as B ON A.permit_reference = B.permit_reference and 
          cast(A.application_date as timestamp) = B.application_date and B.Rn1 = 1

LEFT JOIN AddressUpdate as C ON A.permit_reference = C.permit_reference and 
          cast(A.application_date as timestamp) = C.application_date and C.row_num = 1
          
LEFT JOIN VRMUpdate as D ON A.permit_reference = D.permit_reference and 
          cast(A.application_date as timestamp) = D.permit_application_date and D.row_num = 1

/*WHERE A.import_Date = (Select MAX(import_date) from liberator_permit_fta) AND 
      A.permit_reference not like 'HYV%' AND A.permit_reference not like 'HYS%' AND A.permit_reference not like 'HYQ%' AND
      A.permit_reference not like 'HYF%' AND A.permit_reference not like 'HYJ%' AND A.permit_reference not like 'HYE%' AND
      (A.start_date != '' OR A.end_date != '') and 
      (email_address_of_applicant != 'Liberator.Testers@Hackney.gov.uk' OR surname_of_applicant != 'Tester' OR
       surname_of_applicant != 'Test')*/
/*** and Permit Renewals ***/
UNION ALL

SELECT A.permit_reference, 
       CAST(renewal_application_date as timestamp),
       /*** Applicant details ***/
       forename_of_applicant, surname_of_applicant, email_address_of_applicant, primary_phone, secondary_phone,
       date_of_birth_of_applicant,
  
       /*** Blue Badge details, get tthis from the FTA record (where valid ***/
       CASE
          When D.blue_badge_expiry != '' THEN
             CASE
                When cast(blue_badge_expiry as date) >= cast(substr(renewal_start_date, 1, 10) as date) Then
                  CASE
                      When cast(blue_badge_expiry as date) <= cast(substr(renewal_end_date, 1, 10) as date) Then
                                                                                                    D.blue_badge_number
                      When cast(blue_badge_expiry as date) >= cast(substr(renewal_end_date, 1, 10) as date) Then 
                                                                                                    D.blue_badge_number
                   END
                ELSE ''
             END
       END                       as blue_badge_number,
       CASE
          When D.blue_badge_expiry != '' THEN
             CASE
                When cast(blue_badge_expiry as date) >= cast(substr(renewal_start_date, 1, 10) as date) Then
                  CASE
                      When cast(blue_badge_expiry as date) <= cast(substr(renewal_end_date, 1, 10) as date) Then D.blue_badge_expiry  
                      When cast(blue_badge_expiry as date) >= cast(substr(renewal_end_date, 1, 10) as date) Then D.blue_badge_expiry
                   END  
                ELSE ''
             END
       END                       as blue_badge_expiry,
                                                                           
       /*** start/finish Dates ***/
       cast(substr(renewal_start_date, 1, 10) as date),
       cast(substr(renewal_end_date, 1, 10) as date),

      /*** Approval Details ***/
      B.approval_date, B.approved_by, B.approval_type, 
      
       /*** Payment Details ***/
       renewal_cost, renewal_payment_date, renewal_payment_method, renewal_payment_location, renewal_payment_by, renewal_payment_status,
       /*** Hackney internal ***/
       A.directorate_to_be_charged, A.authorising_officer, A.cost_code, A.subjective_code,
       
       D.permit_type, renewal_ordered_by,
       /*** Business, etc. ***/
       '', '', '',
       /*** Bays, dispensation ***/
       '', '', '', '',
       /*** Address / UPRN ***/
       CASE -- UPRN
          When new_address_effective_from is not NULL Then new_uprn
          ELSE
             CASE
                When renewal_new_uprn != '' Then renewal_new_uprn
                ELSE uprn
             END
       END,
       CASE  -- Address Line 1
          When new_address_effective_from is not NULL Then new_address_line_1
          ELSE
             CASE
                When renewal_new_address_line_1 != '' Then renewal_new_address_line_1
                ELSE address_line_1
             END
       END,       
       CASE  -- Address Line 2
          When new_address_effective_from is not NULL Then new_address_line_2
          ELSE
             CASE
                When renewal_new_address_line_2 != '' Then renewal_new_address_line_2
                ELSE address_line_2
             END
       END,          
       CASE  -- Address Line 3
          When new_address_effective_from is not NULL Then new_address_line_3
          ELSE
             CASE
                When renewal_new_address_line_3 != '' Then renewal_new_address_line_3
                ELSE address_line_3
             END
       END,  
       CASE  -- Postcode
          When new_address_effective_from is not NULL Then new_postcode
          ELSE
             CASE
                When renewal_new_postcode != '' Then renewal_new_postcode
                ELSE postcode
             END
       END,                        
       
       /*** Zone ***/
       CASE  -- CPZ
          When new_address_effective_from is not NULL Then new_cpz
          ELSE
             CASE
                When renewal_new_cpz != '' Then renewal_new_cpz
                ELSE cpz
             END
       END,        
       CASE  -- CPZ Name
          When new_address_effective_from is not NULL Then new_cpz_name
          ELSE
             CASE
                When reneral_new_cpz_name != '' Then reneral_new_cpz_name
                ELSE cpz_name
             END
       END,            
       
       /*** Vehicle ***/
       approval_type, 
       '',
       CASE
          When E.new_vrm is not NULL Then E.new_vrm
          When renewal_new_vrm != '' Then renewal_new_vrm
          When F.new_vrm is not NULL Then F.new_vrm
          ELSE D.vrm
       END, 
       '',
       /*** Flags ***/
       CASE
         When current_date between cast(substr(renewal_start_date, 1, 10) as date) AND
                                                                cast(substr(renewal_end_date, 1, 10) as date) Then 1
         ELSE 0 
       END,       
       1,
       D.Status,
       /*** Try and trap any duplicates records ***/  
       ROW_NUMBER() OVER ( PARTITION BY A.permit_reference,renewal_start_date, renewal_end_date
                                                            ORDER BY A.permit_reference, renewal_application_date DESC) as Rn
  
FROM liberator_permit_renewals as A

/*LEFT JOIN PermitApproval as B ON A.permit_reference = B.permit_reference AND 
                                    approval_date between cast(substr(renewal_start_date, 1, 10) as date) AND            
                                                          cast(substr(renewal_end_date, 1, 10) as date)*/

/*LEFT JOIN AddressUpdate as C ON A.permit_reference = C.permit_reference AND 
                                    new_address_effective_from between cast(substr(renewal_start_date, 1, 10) as date) AND            
                                                                       cast(substr(renewal_end_date, 1, 10) as date) AND
                                    new_address_effective_from > CAST(substr(renewal_application_date,1,10) as date)*/

LEFT JOIN PermitApproval as B ON A.permit_reference = B.permit_reference and 
          CAST(A.renewal_application_date as timestamp) = B.application_date and B.Rn1 = 1
          
LEFT JOIN AddressUpdate as C ON A.permit_reference = C.permit_reference and 
          CAST(A.renewal_application_date as timestamp) = C.application_date and C.row_num = 1
                                    
LEFT JOIN Permit_FTA as D ON A.permit_reference = D.permit_reference

LEFT JOIN VRMUpdate as E ON A.permit_reference = E.permit_reference and 
          cast(A.renewal_application_date as timestamp) = E.permit_application_date and E.row_num = 1 
  
LEFT JOIN VRMLatest as F ON A.permit_reference = F.permit_reference AND F.row_num = 1   
                                                     
WHERE A.import_Date = (Select MAX(import_date) from liberator_permit_renewals) AND
      A.permit_reference not like 'HYV%' AND A.permit_reference not like 'HYS%' AND A.permit_reference not like 'HYQ%' AND
      A.permit_reference not like 'HYF%' AND A.permit_reference not like 'HYJ%' AND A.permit_reference not like 'HYE%' AND
      (renewal_start_date != '' OR renewal_end_date != '')) 
      
/****************************************************************************************************************************/
/*** Finally output the data, WITH The VRM details **/
SELECT 
   A.*,
   /** VRM Details ***/
   make, model, fuel, engine_capactiy, co2_emission, foreign, lpg_conversion, record_created as VRM_record_created,
   /*** identify the current year & previous year ***/
   CASE 
      When F.Fin_Year = (Select Max_Fin_Year From CalendarMAX)                                    Then 'Current'
      When F.Fin_Year = (Select CAST(Cast(Max_Fin_Year as int)-1 as varchar(4)) From CalendarMAX) Then 'Previous'
      Else ''
   END as Fin_Year_Flag,
   /** Financial Year **/
   Fin_Year,
   
   cast(0 as decimal) as usrn,

    current_timestamp as ImportDateTime,
    
    replace(cast(current_date() as string),'-','') as import_date,
    
    -- Add the Import date
    cast(Year(current_date) as string)  as import_year, 
    cast(month(current_date) as string) as import_month,
    cast(day(current_date) as string)   as import_day
   
From Permits as A
LEFT JOIN VRMDetails      as B ON A.permit_reference = B.permit_reference AND A.vrm = B.vrm and B.row_num = 1
LEFT JOIN CalendarFormat  as F ON CAST(A.application_date as date) = date and F.row_num = 1
/*LEFT JOIN LLPG_USRN  as G ON A.uprn = G.uprn*/
Where A.Rn = 1
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_permit_renewals": AmazonS3_node1628163161728,
        "liberator_permit_fta": AmazonS3_node1627053109317,
        "liberator_permit_vrm": AmazonS3_node1628163307688,
        "calendar": AmazonS3_node1632754989503,
        "liberator_permit_vrm_update": AmazonS3_node1628163374473,
        "liberator_permit_address_update": AmazonS3_node1628173244776,
        "liberator_permit_approval": AmazonS3_node1628163229600,
        "liberator_permit_llpg": AmazonS3_node1634550538215,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/Parking_Permit_DeNormalised_Data/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="Parking_Permit_DeNormalised_Data",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
