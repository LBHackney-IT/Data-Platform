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

# Script generated for node liberator_pcn_bailiff
liberator_pcn_bailiff_node1627663703253 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_bailiff",
    transformation_ctx="liberator_pcn_bailiff_node1627663703253",
)

# Script generated for node liberator_pcn_tickets
liberator_pcn_tickets_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_tickets",
    transformation_ctx="liberator_pcn_tickets_node1",
)

# Script generated for node pcnfoidetails_pcn_foi_full
pcnfoidetails_pcn_foi_full_node1627663704845 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-" + environment + "-liberator-refined-zone",
        table_name="pcnfoidetails_pcn_foi_full",
        transformation_ctx="pcnfoidetails_pcn_foi_full_node1627663704845",
    )
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/***

15/11/2021
-remove warning notices from the report by removing “left” join, instead inner join using the warning notice flag in pcnfoidetails_pcn_foi
18/11/2021
-use PCases to count the number of PCNs issued against those VRM’s. The existing VRMCount will only give the number of PCN’s fitting the criteria, but others will be returned in the final report when we join on all PCN’s issued to those VRM’s. Having a count of the number in the final report will be useful
-remove VRM_Count from final report to avoid confusion. Replace with PCN_Count later in the query
-join on TotalPCNs to bring in PCN_Count
24/11/2021
-Added CASE Statement “CaseClosed” to clearly flag cancelled and paid cases.
25/11/2021
-remove the outstanding amount field. Replaced with CASE statement to which only displays the outstandingamount ticket is not cancelled or paid.

***/

/**CTE to determine all PCN's in the given stage criteria in the Persistent Evaders Spec**/

WITH PCNCriteria AS
	(SELECT DISTINCT ticketserialnumber, VRM
     FROM liberator_pcn_tickets
	 WHERE progressionstage IN ('cc','nodr','foreigncollection','nodrr','predebt','pre-debt','warr','warrant')
     AND whenpaid = ''
     AND whencancelled = ''
     AND import_date = (SELECT MAX(import_date) FROM liberator_pcn_tickets)),

/*** use PCNCriteria to count the number of PCNs issued against those VRM’s***/

MultiPCN AS
    (SELECT VRM, Count (*) as VRM_Count
     FROM PCNCriteria
     GROUP BY VRM),

/**Inner Join to return VRM's with PCN's in the given criteria which have been issued with 3 or more PCN's, and have received a PCN within the last 60 days***/

PCNlast60days AS
	(SELECT distinct A.PCN,
	                 A.pcnissuedate,
	                 datediff(current_date, pcnissuedate) as dayssinceissued,
                     B.VRM,
                     B.VRM_Count
                     FROM (SELECT * FROM
                     pcnfoidetails_pcn_foi_full
                     WHERE datediff(current_date, pcnissuedate)<=60
                     AND import_date = (SELECT MAX(import_date)
                     FROM pcnfoidetails_pcn_foi_full)) AS A
		             JOIN (SELECT * FROM MultiPCN
		             WHERE VRM_Count >=3) AS B ON A.VRM = B.VRM),

/*** From the VRM's identified in the PCNLast60days create a list of distinct VRM's with PCN's fitting the stage criteria and PCN Count ***/

PEVRMS as (SELECT Distinct VRM, VRM_Count FROM PCNlast60days),

/**return all columns from spec. inner join on distinct list of VRM's**/

PCases AS
         (SELECT DISTINCT A.ticketserialnumber,
          A.VRM,
          A.make,
          A.model,
          A.colour,
          A.contraventiondateandtimewith,
          B.VRM AS PersistVRM,
          CASE
              When tickettype IN ('CCTV_BusLane','CCTV Bus Lane','CCTV Bus Lane_On Street') Then 'CCTV_BusLane'
              When tickettype IN ('CCTV_Moving','CCTV Moving traffic','CCTV Moving traffic_On Street') Then 'CCTV_Moving'
              When tickettype IN ('CCTV_Parking','CCTV static','CCTV static_On Street') Then 'CCTV_Parking'
              When tickettype IN ('hht') Then 'CEO'
              Else tickettype
          End AS DebtType,
          A.progressionstage,
          A.assoclocation AS location,
          A.osoppwhere AS whereonlocation,
          A.cpzname AS Zone,
          A.contraventioncode,

          CASE
              When whenpaid NOT IN ('') or whencancelled NOT IN ('') Then NULL
              Else C.lib_initial_debt_amount
          End AS OutstandingAmount,

          CASE
              When whenpaid NOT IN ('') or whencancelled NOT IN ('') then 'Yes'
	          Else 'No'
          End AS CaseClosed,


          CASE
              When progressionstage IN ('warrant') Then 'Yes'
              Else 'No'
          End AS WarrantIssued,

          D.warrantissuedate,
          D.organisation,
          Case
              When holdreason in ('') Then 'No'
              Else 'Yes'
          End AS OnHold,
          A.holdreason,
          CASE
              When CAST(A.contraventiondateandtime as date) <= date_Add(current_date, -60) Then 'No'
              Else 'Yes'
          END AS PCN_Last_60_days,

          ROW_NUMBER() OVER (PARTITION BY ticketserialnumber ORDER BY ticketserialnumber DESC) as Rn,

        date_format(current_date, 'yyyy') AS import_year,
        date_format(current_date, 'MM') AS import_month,
        date_format(current_date, 'dd') AS import_day,
        date_format(current_date, 'yyyyMMdd') AS import_date

FROM (SELECT * FROM liberator_pcn_tickets
      WHERE import_date = (SELECT MAX(import_date)
      FROM liberator_pcn_tickets)) AS A
      JOIN (SELECT * FROM PEVRMS) AS B ON A.VRM = B.VRM

      JOIN (SELECT PCN, lib_initial_debt_amount, warningflag
      FROM pcnfoidetails_pcn_foi_full
      WHERE warningflag = 0
      AND import_date = (SELECT MAX(import_date)
      FROM pcnfoidetails_pcn_foi_full)) AS C
      ON A.ticketserialnumber = C.PCN

      LEFT JOIN (SELECT ticketreference, warrantissuedate, organisation
      FROM liberator_pcn_bailiff
      WHERE import_date = (SELECT MAX(import_date)
      FROM liberator_pcn_bailiff)) AS D
      ON A.ticketserialnumber = D.ticketreference),

/** count the total number of PCNs issued against the VRM’s in PCases**/

TotalPCNs AS (SELECT VRM as PCNVRM, Count (*) as PCN_Count
     	      FROM PCases
     	      WHERE Rn = 1
     	      GROUP BY VRM),

/*** Select final list of PCN’s removing the duplicates using a row number filter join with TotalPCNs to bring in the PCN_Count***/

PCNPersistentEvaders AS (SELECT A.*,
                                B.*
                         FROM (SELECT * FROM PCases
                               WHERE Rn = 1
                               ORDER BY VRM, contraventiondateandtimewith) AS A
                         JOIN (SELECT PCNVRM, PCN_Count FROM TotalPCNs) AS B
                         ON A.VRM = B.PCNVRM)

SELECT * FROM PCNPersistentEvaders

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "liberator_pcn_bailiff": liberator_pcn_bailiff_node1627663703253,
        "liberator_pcn_tickets": liberator_pcn_tickets_node1,
        "pcnfoidetails_pcn_foi_full": pcnfoidetails_pcn_foi_full_node1627663704845,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_Persistent_Evaders/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Persistent_Evaders",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
