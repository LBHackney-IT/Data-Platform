import sys
import time
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, create_pushdown_predicate
environment = get_glue_env_var("environment")


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    """
    Define a function to execute SQL queries using Spark SQL
    Register each DynamicFrame as a temporary view to use in the SQL query
    Execute the SQL query
    Convert the result back to a DynamicFrame
    """
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])

# Initialize Spark and Glue contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node liberator_pcn_payments
# Load various datasets from the Glue Catalog, applying a pushdown predicate to filter data based on 'import_date'
# Each dataset corresponds to a different aspect of PCN data, such as payments, bailiff actions, tickets, etc.
start_time = time.time()

liberator_pcn_payments_node1624544303612 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_pcn_payments",
        transformation_ctx="liberator_pcn_payments_node1624544303612",
        push_down_predicate=create_pushdown_predicate("import_date",1)
    )
)


# Repeat the process for the other datasets
# Script generated for node Amazon S3
AmazonS3_node1632737645295 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1632737645295",
)

# Script generated for node liberator_pcn_bailiff
liberator_pcn_bailiff_node1624546972989 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_bailiff",
    transformation_ctx="liberator_pcn_bailiff_node1624546972989",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1632316748934 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_ic",
    transformation_ctx="AmazonS3_node1632316748934",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node liberator_pcn_tickets
liberator_pcn_tickets_node1624456646816 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_tickets",
    transformation_ctx="liberator_pcn_tickets_node1624456646816",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node Amazon S3
AmazonS3_node1625039493203 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="pcnfoidetails_pcn_event_log",
    transformation_ctx="AmazonS3_node1625039493203",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)

# Script generated for node liberator_pcn_warrant_redistribution
liberator_pcn_warrant_redistribution_node1624611344521 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-raw-zone",
        table_name="liberator_pcn_warrant_redistribution",
        transformation_ctx="liberator_pcn_warrant_redistribution_node1624611344521",
        push_down_predicate=create_pushdown_predicate("import_date",1)
    )
)

# Script generated for node liberator_pcn_appeals
liberator_pcn_appeals_node1624617107363 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_appeals",
    transformation_ctx="liberator_pcn_appeals_node1624617107363",
    push_down_predicate=create_pushdown_predicate("import_date",1)
)
print(f"loading data {(time.time() - start_time)/60:.2f} minutes")

# Script generated for node ApplyMapping
# Define a SQL query to denormalise PCN data, combining information from various sources into a single record per PCN
start_time = time.time()
SqlQuery0 = """
/*************************************************************************************************************************
Parking_PCN_Denormalisation

The SQL builds a PCN de-normalisation table, single PCN record with all data that is useful

09/07/2021 - Create SQL. 
13/07/2021 - add additional code to ensure latest records are collected
23/07/2012 - add code to identify if the PCN was issued in the last 30 days
07/09/2021 - add Cancel by
22/09/2021 - Add code to identify if Corresp has been sent
27/09/2021 - Add code to identify Current & Previous year and Fin Year
20/10/2021 - add issue date / time
*************************************************************************************************************************/

/*** Because of duplication index on the LATEST record ***/
WITH ETA_Dates as (SELECT *, ROW_NUMBER() OVER ( PARTITION BY ticketserialnumber
                     ORDER BY ticketserialnumber, decisionreceived DESC) row_num
FROM liberator_pcn_appeals as A
WHERE import_date = (Select MAX(import_date) from liberator_pcn_appeals)),

/*** Bailiff Records ***/
Bailiff AS (SELECT *, ROW_NUMBER() OVER ( PARTITION BY ticketreference
                     ORDER BY ticketreference, warrantissuedate DESC) row_num
FROM liberator_pcn_bailiff as A
WHERE import_date = (Select MAX(import_date) from liberator_pcn_bailiff)),

Calendar as (
Select * From calendar
WHERE import_date = (Select MAX(import_date) from calendar)),

CalendarMAX as (
Select MAX(fin_year) as Max_Fin_Year From calendar
WHERE import_date = (Select MAX(import_date) from calendar)),

/*** Identify those PCNs with Disputed Corresp ***/ 
Corresp as (
   SELECT DISTINCT 
      ticketserialnumber, import_date
   FROM liberator_pcn_ic 
   where import_Date = (Select MAX(import_date) from liberator_pcn_ic)
   AND date_received != '' AND response_generated_at != ''
   AND char_length(ticketserialnumber) = 10
   AND Serviceable IN ('Challenges','Key worker','Removals','TOL','Charge certificate','Representations')),

/*** Identify those PCNs with Keyworker Disputed Corresp ***/ 
KeyWorker_Dispute as (
   SELECT DISTINCT 
      ticketserialnumber, import_date
   FROM liberator_pcn_ic 
   where import_Date = (Select MAX(import_date) from liberator_pcn_ic)
   AND date_received != '' AND response_generated_at != ''
   AND char_length(ticketserialnumber) = 10
   AND Serviceable IN ('Key worker')),

pcn_warrant_redistribution as (
   SELECT *, ROW_NUMBER() OVER ( PARTITION BY PCN
                     ORDER BY PCN, processedon DESC) row_num 
   FROM liberator_pcn_warrant_redistribution
   WHERE import_date = (Select MAX(import_date) from liberator_pcn_warrant_redistribution))

/*** Output the data ***/
SELECT A.ticketserialnumber       AS PCN,
       CAST(A.contraventiondateandtime as date)          AS PCNIssueDate,
       CAST(A.contraventiondateandtimewith as timestamp) AS PCNIssueDateTime,
       CASE When A.whencancelled !='' THEN CAST(A.whencancelled  as date) ELSE CAST(NULL as date) END AS PCN_Canx_Date,
       A.cancellationgroup        AS CancellationGroup,
       replace(replace(A.cancellationreason, '\r',''), '\n','') AS CancellationReason,    
       CASE When A.whenpaid !='' THEN CAST(A.whenpaid  as date) ELSE CAST(NULL as date) END AS PCN_CaseClosedDate, 
       
       -- Issued Location
       assoclocation            AS Street_Location,
       osoppwhere               AS WhereOnLocation,
       cpzname                  AS Zone,
       streetusrn               AS USRN,
       contraventioncode,contraventionsuffix,
       
       CASE When tickettype = 'hht' Then 'CEO' Else tickettype End AS DebtType,      
       -- Vehicle Details
       A.vrm                    AS VRM,
       make                     AS VehicleMake,
       model                    AS VehicleModel,
       colour                   AS VehicleColour,
       -- CEO Details
       shoulder_number          AS CEO,
       issuingdeviceid          AS CEODevice,

       -- Set Flags
       CASE 
          When CAST(A.contraventiondateandtime as date) <= date_Add(current_date,-30) Then 0 
          Else 1 
       END                                                            AS Current_30_Day_Flag, -- MRB 23-07-2021
                 
       CASE When vehicledrivenaway = 'Yes'          Then 1 Else 0 END AS IsVDA,
       CASE When A.cancellationreason like '%Void%' Then 1 Else 0 END AS IsVoid,
       remove                                                         AS IsRemoval,
       driverseen,
       allwindows,
       parkedonfootway, 
       doctor,  
       CASE 
          When contraventioncode like 'W%'            Then 1
          When progressionstage = 'warningnoticesent' Then 1
          ELSE 0
       END as WarningFlag,
       
       -- Progression Stage(s)
       progressionstage           AS ProgressionStage,
       nextprogressionstage       AS NextProgressionStage,
       nextprogressionstagestarts AS NextProgressionStageStarts,
       holdreason                 AS HoldReason, 
       
       -- Liberator Payment Details
       B.total_amount                        AS Lib_Initial_Debt_Amount,
       CASE
          WHEN B.payment_received != '0.000' THEN CAST(-CAST(B.payment_received as double) as varchar(10))
          ELSE '0'
       END                                   AS Lib_Payment_Received,
       
       CASE
          WHEN B.write_off_amount != '0.000' THEN CAST(-CAST(B.write_off_amount as double) as varchar(10))
          ELSE '0'
       END                                   AS Lib_Write_Off_Amount,
       
       B.payment_void                        AS Lib_Payment_Void,
       B.payment_method                      AS Lib_Payment_Method, 
       B.payment_reference                   AS Lib_Payment_Ref,
    
       -- Warrant redistribution
       C.partyfrom                  as Baliff_From, 
       C.redistributedto            as Bailiff_To,  
       C.processedon                as Bailiff_ProcessedOn,
       C.redistributionreason       AS Bailiff_RedistributionReason, 
       
       -- Bailiff PCN Data
       D.organisation as Bailiff, 
       D.warrantissuedate, 
       D.allocation,

       -- ETA Appeal Details
       E.datenotified     as ETA_datenotified, 
       E.packsubmittedon  as ETA_packsubmittedon, 
       E.evidencedate     as ETA_evidencedate, 
       E.adjudicationdate as ETA_adjudicationdate, 
       E.appealgrounds    as ETA_appealgrounds, 
       E.decisionreceived as ETA_decisionreceived, 
       E.outcome          as ETA_outcome, 
       E.packsubmittedby  as ETA_packsubmittedby,
       
        /*** Add Cancelled By ***/
       A.cancelledby,
       
       /*** Owner/Keeper address ***/
       registered_keeper_address, current_ticket_address,
       
       /*** Dispute Corresp registered ***/
       CASE
          When G.ticketserialnumber is not NULL Then 1
          Else 0
        END as Corresp_Dispute_Flag,

       /*** Keyworker Dispute Corresp registered ***/
       CASE
          When I.ticketserialnumber is not NULL Then 1
          Else 0
        END as Keyworker_Corresp_Dispute_Flag,

       /*** identify the current year ***/
       CASE 
          When H.Fin_Year = (Select Max_Fin_Year From CalendarMAX)                                    Then 'Current'
          When H.Fin_Year = (Select CAST(Cast(Max_Fin_Year as int)-1 as varchar(4)) From CalendarMAX) Then 'Previous'
          Else ''
       END as Fin_Year_Flag,
       
       H.Fin_Year,
        
        -- Event Log
        F.*,
        
        current_timestamp() as ImportDateTime,   
        
        replace(cast(current_date() as string),'-','') as import_date,

        cast(A.import_year as string)  as import_year, 
        cast(A.import_month as string) as import_month, 
        cast(A.import_day as string)   as import_day
       
FROM liberator_pcn_tickets as A

LEFT JOIN liberator_pcn_payments               as B ON A.ticketserialnumber = B.ticket_ref AND
(A.import_date = B.import_date)

LEFT JOIN pcn_warrant_redistribution as C ON A.ticketserialnumber = C.pcn AND
(A.import_date = C.import_date) AND C.row_num = 1

LEFT JOIN Bailiff as D ON A.ticketserialnumber = D.ticketreference AND
(A.import_date = D.import_date) AND D.row_num = 1

LEFT JOIN ETA_Dates                            as E ON A.ticketserialnumber = E.ticketserialnumber AND
(A.import_date = E.import_date) AND E.row_num = 1

LEFT JOIN pcnfoidetails_pcn_event_log           as F ON A.ticketserialnumber = F.ticket_ref AND
(A.import_date = F.import_date)

LEFT JOIN Corresp as G ON A.ticketserialnumber = G.ticketserialnumber AND
(A.import_date = G.import_date)

LEFT JOIN Calendar as H ON CAST(A.contraventiondateandtime as date) 
                                           = cast(substr(H.date, 1, 10) as date)

LEFT JOIN KeyWorker_Dispute as I ON A.ticketserialnumber = I.ticketserialnumber AND
(A.import_date = I.import_date)

WHERE A.ticketserialnumber not IN ('QZ01017688','QZ08427983','QZ99999990','QZ00887560') AND
      A.import_Date = (Select MAX(import_date) from liberator_pcn_tickets)
"""

# Execute the SQL query defined above, passing the loaded DynamicFrames as mappings to be used in the query
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_payments": liberator_pcn_payments_node1624544303612,
        "calendar": AmazonS3_node1632737645295,
        "liberator_pcn_bailiff": liberator_pcn_bailiff_node1624546972989,
        "liberator_pcn_ic": AmazonS3_node1632316748934,
        "liberator_pcn_tickets": liberator_pcn_tickets_node1624456646816,
        "pcnfoidetails_pcn_event_log": AmazonS3_node1625039493203,
        "liberator_pcn_warrant_redistribution": liberator_pcn_warrant_redistribution_node1624611344521,
        "liberator_pcn_appeals": liberator_pcn_appeals_node1624617107363,
    },
    transformation_ctx="ApplyMapping_node2",
)
print(f"transform and mapping based on SQL query {(time.time() - start_time)/60:.2f} minutes")

# Script generated for node PCN_DeNormalisation
# Configure the output sink to write the transformed data to an S3 bucket in Parquet format
# The data is partitioned by import date components for efficient storage and query performance
start_time = time.time()
PCN_DeNormalisation_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/PCNFOIDetails_PCN_FOI_FULL/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="PCN_DeNormalisation_node3",
)
# Set catalog information for the output data, specifying the database and table name in the Glue Data Catalog
PCN_DeNormalisation_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="PCNFOIDetails_PCN_FOI_FULL",
)
# spefify the output as parquet format
PCN_DeNormalisation_node3.setFormat("glueparquet")
# Write the transformed data frame to the specified S3 path
PCN_DeNormalisation_node3.writeFrame(ApplyMapping_node2)
print(f"writing to S3 bucket {(time.time() - start_time)/60:.2f} minutes")

job.commit()
