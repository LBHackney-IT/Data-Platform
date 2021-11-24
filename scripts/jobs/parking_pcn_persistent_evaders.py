import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame


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
    database="dataplatform-stg-liberator-raw-zone",
    table_name="liberator_pcn_bailiff",
    transformation_ctx="liberator_pcn_bailiff_node1627663703253",
)

# Script generated for node liberator_pcn_tickets
liberator_pcn_tickets_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-stg-liberator-raw-zone",
    table_name="liberator_pcn_tickets",
    transformation_ctx="liberator_pcn_tickets_node1",
)

# Script generated for node pcnfoidetails_pcn_foi_full
pcnfoidetails_pcn_foi_full_node1627663704845 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="dataplatform-stg-liberator-refined-zone",
        table_name="pcnfoidetails_pcn_foi_full",
        transformation_ctx="pcnfoidetails_pcn_foi_full_node1627663704845",
    )
)

# Script generated for node ApplyMapping
SqlQuery0 = """
WITH MultiPCN AS
              (SELECT VRM, Count (*) as VRM_Count
              FROM liberator_pcn_tickets
              WHERE progressionstage IN ('cc','nodr','foreigncollection','nodrr','predebt','pre-debt','warr','warrant')
              AND whenpaid = ''
              AND whencancelled = '' and import_date = (SELECT MAX(import_date) FROM liberator_pcn_tickets)
              GROUP BY VRM),
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
                        C.lib_initial_debt_amount AS OutstandingAmount,
                        B.VRM_Count,
                        CASE
        When A.progressionstage IN ('warrant') Then 'Yes'
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
                        END AS PCN_Last_60_Days,
                             
        ROW_NUMBER() OVER (PARTITION BY ticketserialnumber
        ORDER BY ticketserialnumber DESC) as Rn,

                        A.import_year, A.import_month, A.import_day,
                        current_date as import_date

        FROM (SELECT *
              FROM liberator_pcn_tickets
              WHERE progressionstage IN ('cc','nodr','foreigncollection','nodrr','predebt','pre-debt','warr','warrant') and
              import_date = (SELECT MAX(import_date) FROM liberator_pcn_tickets)
              AND whenpaid = ''
              AND whencancelled = '') AS A
              JOIN (SELECT * FROM MultiPCN
                    WHERE VRM_Count >=3) AS B ON A.VRM = B.VRM
              LEFT JOIN (SELECT PCN, lib_initial_debt_amount
                         FROM pcnfoidetails_pcn_foi_full
                         WHERE ImportDatTime = (SELECT MAX(ImportDatTime) FROM pcnfoidetails_pcn_foi_full)) AS C ON A.ticketserialnumber = C.PCN
              LEFT JOIN (SELECT ticketreference, warrantissuedate, organisation
                         FROM liberator_pcn_bailiff
                         WHERE import_date = (SELECT MAX(import_date) FROM liberator_pcn_bailiff)) AS D
                         ON A.ticketserialnumber = D.ticketreference),
PCNPersistentEvaders AS
                     (SELECT * FROM PCases
                     WHERE Rn = 1
	         AND PCN_Last_60_days = 'Yes'
                     ORDER BY VRM, contraventiondateandtimewith)
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
    path="s3://dataplatform-stg-refined-zone/parking/liberator/Parking_PCN_Persistent_Evaders/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-stg-liberator-refined-zone",
    catalogTableName="Parking_PCN_Persistent_Evaders",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
