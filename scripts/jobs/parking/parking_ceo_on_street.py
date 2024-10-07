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
AmazonS3_node1628173244776 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_ceo",
    transformation_ctx="AmazonS3_node1628173244776",
)

# Script generated for node Amazon S3
AmazonS3_node1632912445458 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-raw-zone",
    table_name="liberator_pcn_cb",
    transformation_ctx="AmazonS3_node1632912445458",
)

# Script generated for node Amazon S3
AmazonS3_node1636704737623 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="ceo_beat_streets",
    transformation_ctx="AmazonS3_node1636704737623",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/***************************************************************************************************************************
Parking_CEO_On_Street

This SQL creates the On Street log, ONLY the start street/end street & PCN

30/09/2021 - create SQL
09/11/2021 - Amend because PCN was against the ES street - remove filter for PCN
11/11/2021 - rewrite to add beat details and time on street for ES records
18/11/2021 - amend because Observation was against the ES street - remove filter for Observed
25/11/2021 - force the street names to lowercase
***************************************************************************************************************************/
/*** Get the Beat streets ***/
with BeatStreet as (
   SELECT
      beatid, beatname, lower(streetname) as streetname
   FROM ceo_beat_streets
   WHERE import_Date = (Select MAX(import_date) from ceo_beat_streets)),

/*** Collect the On Street data ***/
CEO_OnStreet as (
   SELECT
   row_number() over (partition by officer_shoulder_no, cast(substr(officer_patrolling_date, 1, 10) as date)
                    order by officer_shoulder_no,officer_patrolling_date) as Row_Num,
   cast(substr(officer_patrolling_date, 1, 10) as date) as Patrol_Date,
   officer_shoulder_no,
   /** force the street name to lower ***/
   lower(officer_street_name) as officer_street_name,
   Cast(officer_patrolling_date as timestamp) as officer_patrolling_date,
   break_duration,ticket_number, observation_date,cpzname,vrm,
   length(ltrim(Ticket_number)) as T_Len
   FROM liberator_pcn_ceo
   WHERE /*import_Date = (Select MAX(import_date) from liberator_pcn_ceo) AND*/
   officer_street_name != 'null' AND officer_street_name !=    ''
   /*AND VRM != 'OBSERVED'*/ AND officer_street_name != 'CEO on break'
   order by officer_shoulder_no, officer_patrolling_date),

/*** Get the summerised list of CEO/Dates */
CEO_Date as (
   Select officer_shoulder_no as CEO, cast(officer_patrolling_date as date) as Patrol_Date
   From CEO_OnStreet
   Group By officer_shoulder_no, cast(officer_patrolling_date as date)),

/*** Identify the Street start/end and flag the PCN records ***/
On_Street_Ident as (
   Select
   A.*, CAST(B.officer_patrolling_date as timestamp) as officer_patrolling_date, B.officer_street_name as Street, B.ticket_number, B.vrm,
   B.observation_date, B.cpzname,
   /*** Flags SS - Start Street/ES - End Street/ PCN - PCN issued***/
   CASE
      When B.Row_Num = 1                                                                                      Then 'SSS'
      When B.officer_street_name != C.officer_street_name AND B.officer_street_name != D.officer_street_name  Then 'SS/ES'
      When B.officer_street_name = C.officer_street_name AND B.officer_street_name != D.officer_street_name   Then 'SS'
      When B.officer_street_name = C.officer_street_name AND B.officer_street_name = D.officer_street_name
                                                                                         AND B.T_Len < 8      Then 'null'
      When B.officer_street_name != C.officer_street_name AND B.officer_street_name != D.officer_street_name
                                                                                         AND B.T_Len < 8      Then 'null'
      When B.officer_street_name != C.officer_street_name                                                     Then 'ES'
      When B.T_Len >= 10                                                                                      Then 'PCN'
      When C.Row_Num is NULL                                                                                  Then 'ESS'
      When C.Row_Num = 1                                                                                      Then 'ESS'
   Else 'null'
   END as Status_Flag
   From CEO_Date as A
   inner join CEO_OnStreet as B ON A.CEO = B.officer_shoulder_no AND A.Patrol_Date = B.Patrol_Date
   /** Rec AFTER ***/
   left join CEO_OnStreet as C ON A.CEO = C.officer_shoulder_no AND A.Patrol_Date = C.Patrol_Date AND C.Row_num = B.Row_Num+1
   /*** Rec BEFORE ***/
   left join CEO_OnStreet as D ON A.CEO = D.officer_shoulder_no AND A.Patrol_Date = D.Patrol_Date AND D.Row_num = B.Row_Num-1
   order by B.officer_shoulder_no, B.officer_patrolling_date),

/*** Beat Info from APCOA ***/
CEO_Beat as (
   SELECT activity_date, ceo_shoulder_no, beat, shift, beat_start_point, method_of_travel, travel_time, shift_start_time, shift_end_time
   FROM liberator_pcn_cb
   WHERE import_Date = (Select MAX(import_date) from liberator_pcn_cb)),

/*** Get the start street and end street and create a record number ***/
Order_Streets as (
   SELECT
   CEO, Patrol_Date, officer_patrolling_date, street, status_flag,
   row_number() over (partition by CEO, Patrol_Date
                    order by CEO, officer_patrolling_date) as Row_Num
   FROM On_Street_Ident
   WHERE Status_Flag IN ('SSS','SS','ES','ESS')),

/*** using the data above get the amount of time that the CEO was on the street ***/
Time_On_Street as (
   SELECT
      A.*,
      unix_timestamp(A.officer_patrolling_date)- unix_timestamp(D.officer_patrolling_date) as TimeOnStreet_Secs

   FROM Order_Streets as A
   left join Order_Streets as D ON A.CEO = D.CEO AND A.Patrol_Date = D.Patrol_Date AND D.Row_num = A.Row_Num-1
   WHERE A.Status_flag IN ('ES','ESS')),

/*** Merge Data ***/
Display_Data as (
   SELECT
      A.*,
      B.beat, B.shift, B.beat_start_point, B.method_of_travel, B.travel_time, B.shift_start_time, B.shift_end_time,
      C.beatname, C.streetname

   FROM On_Street_Ident     as A
   LEFT JOIN CEO_Beat       as B ON A.CEO = B.ceo_shoulder_no AND A.Patrol_Date = B.activity_date
   LEFT JOIN BeatStreet     as C ON B.Beat = C.Beatname AND A.Street = C.streetname
   WHERE Status_Flag != 'null'
   Order by A.CEO, A.Officer_patrolling_date)

SELECT A.*, B.TimeOnStreet_Secs,

    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date

FROM Display_Data as A
LEFT JOIN Time_On_Street as B ON A.CEO = B.CEO and A.officer_patrolling_date = B.officer_patrolling_date
                                                                                and A.Status_Flag = B.status_flag
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "ceo_beat_streets": AmazonS3_node1636704737623,
        "liberator_pcn_ceo": AmazonS3_node1628173244776,
        "liberator_pcn_cb": AmazonS3_node1632912445458,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_CEO_On_Street/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_CEO_On_Street",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
