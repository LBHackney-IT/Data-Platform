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
AmazonS3_node1632912445458 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="calendar",
    transformation_ctx="AmazonS3_node1632912445458",
)

# Script generated for node Amazon S3
AmazonS3_node1633593610551 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="ceo_visit_req_timings",
    transformation_ctx="AmazonS3_node1633593610551",
)

# Script generated for node Amazon S3
AmazonS3_node1633593851886 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="parking_ceo_on_street",
    transformation_ctx="AmazonS3_node1633593851886",
    #teporarily removed while table partitions are fixed
    #push_down_predicate=create_pushdown_predicate("import_date", 7),
)

# Script generated for node Amazon S3
AmazonS3_node1633594330463 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="ceo_beat_visit_requirements",
    transformation_ctx="AmazonS3_node1633594330463",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/***************************************************************************************************************************
Parking_Deployment_Target_Details

This SQL calculates the deployment details against agreed targets

07/10/2021 - create SQL
***************************************************************************************************************************/
/*** Format the date because Calendar data imported with different date formats!!! ***/
With CalendarFormat as (
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
      ROW_NUMBER() OVER ( PARTITION BY date 
                       ORDER BY  date, import_date DESC) row_num
   FROM calendar),
    
/*** Continue formatting the Calendar data, get first and last date of the month, etc ***/
cteCalendarBefore as (
select distinct
   date_format(cast(date as timestamp), "M")                            as Month,
   MIN(date)                                                            as MonthStart,
   MAX(date)                                                            as MonthEnd,
   SUM(CASE When workingday = '1' AND holiday = '0' Then 1 ELSE 0 END)  as TotWorkingDays,
   SUM(CASE When workingday = '0' AND holiday = '0' Then 1 ELSE 0 END)  as NonWorkingDays
FROM CalendarFormat
WHERE date >= (Select cast(substr(fin_year_startdate, 1, 10) as date) FROM CalendarFormat
               Where date = current_date AND row_num = 1)
group by month(cast(date as timestamp)),year(cast(date as timestamp)),date_format(cast(date as timestamp), "M")),

CalendarFULL as (
   Select 
      date, 
      cast(substr(cast(date as string), 1, 8)||'01' as date) As FinMonthStartDate,
      workingday, 
      dow,
      holiday, 
      fin_year, 
      fin_year_startdate, 
      fin_year_enddate
FROM CalendarFormat),

/***************************************************************************************************************************************
Populate the Deployment timings table
***************************************************************************************************************************************/
DepTimings as (
select full_cpz,
   CASE When mfam != '' Then substr(mfam, 1, 5)||':00' else cast(null as string) end as mfam_B,
   CASE When mfam != '' Then substr(mfam, 7, 5)||':00' else cast(null as string) end as mfam_E,
   /***********************************************************************************************/
   CASE When mfpm != '' Then substr(mfpm, 1, 5)||':00' else cast(null as string) end as mfpm_B,
   CASE When mfpm != '' Then substr(mfpm, 7, 5)||':00' else cast(null as string) end as mfpm_E,
   /***********************************************************************************************/  
   CASE When mfev != '' Then substr(mfev, 1, 5)||':00' else cast(null as string) end as mfev_B,
   CASE When mfev != '' Then substr(mfev, 7, 5)||':00' else cast(null as string) end as mfev_E, 
   /***********************************************************************************************/  
   CASE When mfat != '' Then substr(mfat, 1, 5)||':00' else cast(null as string) end as mfat_B,
   CASE When mfat != '' Then substr(mfat, 7, 5)||':00' else cast(null as string) end as mfat_E, 
   /***********************************************************************************************/
   CASE When satam != '' Then substr(satam, 1, 5)||':00' else cast(null as string) end as satam_B,
   CASE When satam != '' Then substr(satam, 7, 5)||':00' else cast(null as string) end as satam_E,
   /***********************************************************************************************/  
   CASE When satpm != '' Then substr(satpm, 1, 5)||':00' else cast(null as string) end as satpm_B,
   CASE When satpm != '' Then substr(satpm, 7, 5)||':00' else cast(null as string) end as satpm_E,
   /***********************************************************************************************/     
   CASE When satev != '' Then substr(satev, 1, 5)||':00' else cast(null as string) end as satev_B,
   CASE When satev != '' Then substr(satev, 7, 5)||':00' else cast(null as string) end as satev_E
FROM ceo_visit_req_timings
WHERE import_Date = (Select MAX(import_date) from ceo_visit_req_timings) AND full_cpz != 'X Parking Zone'),

Visit_Req as (
   SELECT * 
   from ceo_beat_visit_requirements
   WHERE import_Date = (Select MAX(import_date) from ceo_visit_req_timings)),

/***************************************************************************************************************************************
Populate the Deployment Targets table
***************************************************************************************************************************************/
cteCalendarSummary as (
SELECT 
   MonthStart,
   
   lower(CASE
     When street_name = 'Kingsland Road ©' Then 'Kingsland Road (C)'
     ELSE Street_Name
   END) as Street_Name,
   
   CASE
      When CPZ = 'EST' Then 'Estates'
      When CPZ = 'CP'  Then 'Car Parks'
      ELSE CPZ
   END as CPZ,
  
   cast((MFAM) as int) * TotWorkingDays      MFAM,
   cast((MFPM) as int) * TotWorkingDays      MFPM,
   cast((MFEV) as int) * TotWorkingDays      MFEV,
   cast((MFAT) as int) * TotWorkingDays      MFAT,
   cast((SATAM) as int) * NonWorkingDays/2   SATAM,
   cast((SATPM) as int) * NonWorkingDays/2   SATPM,
   cast((SATEV) as int) * NonWorkingDays/2   SATEV
  
FROM cteCalendarBefore cross join Visit_Req 
WHERE MonthEnd <= current_date AND cpz != 'X'),

/***************************************************************************************************************************************
Create the on-street list, and add time zone
***************************************************************************************************************************************/
On_Street_Breakdown as (
   SELECT
      CEO,
      patrol_date,
      FinMonthStartDate,
      officer_patrolling_date as patrol_time,
      lower(Street) as Street, CPZname,
      CASE
         When dow IN ('Monday','Tuesday','Wednesday','Thursday','Friday') Then
            CASE
               When officer_patrolling_date between 
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||mfam_B as timestamp) AND
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||mfam_E as timestamp) Then 'MFAM'
                When officer_patrolling_date between 
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||mfpm_B as timestamp) AND
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||mfpm_E as timestamp) Then 'MFPM'  
                When officer_patrolling_date between 
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||mfev_B as timestamp) AND
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||mfev_E as timestamp) Then 'MFEV'  
                ELSE 'MFAT'
            END
         When dow IN ('Saturday') Then
            CASE
               When officer_patrolling_date between 
                        CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||satam_B as timestamp) AND
                        CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||satam_E as timestamp) Then 'SATAM'  
               When officer_patrolling_date between 
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||satpm_B as timestamp) AND
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||satpm_E as timestamp) Then 'SATPM' 
               When officer_patrolling_date between 
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||satev_B as timestamp) AND
                         CAST(substr(cast(officer_patrolling_date as string), 1, 10)||' '||satev_E as timestamp) Then 'SATEV' 
              ELSE 'SATAT'
            END
         ELSE dow
      END as TimeZone   
   FROM parking_ceo_on_street as A

   LEFT JOIN CalendarFULL as C ON A.patrol_date = C.date
   LEFT JOIN DepTimings as D ON A.cpzname = D.full_cpz

   WHERE import_Date = (Select MAX(import_date) from parking_ceo_on_street) AND status_flag IN ('SS/ES', 'SS', 'SSS')
   AND A.street != 'CEO In transit'),
      
/***************************************************************************************************************************************
Summerise the on-street & time zone to date/street/zone & timezone
***************************************************************************************************************************************/
On_Street_Summary as (
   SELECT
      cpzname, street,
      FinMonthStartDate, TimeZone,
      count(*) as TotalNoOfVisits
   FROM On_Street_Breakdown
   WHERE TimeZone != 'Sunday'
   GROUP BY cpzname, street,FinMonthStartDate, TimeZone),
   
/***************************************************************************************************************************************
Bring the Summary and Target records togather
***************************************************************************************************************************************/
Display_Data as (
   SELECT 
      MonthStart as Month, Street_Name, CPZ, B.cpzname,
      /** Collect the Target values ***/
      MFAM, MFPM, MFEV, MFAT, SATAM, SATPM, SATEV,
    
      /** Collect the actual number of times the road was visited ***/
      coalesce(B.TotalNoOfVisits,0) as Act_MFAM,
      coalesce(C.TotalNoOfVisits,0) as Act_MFPM,
      coalesce(D.TotalNoOfVisits,0) as Act_MFEV,
      coalesce(E.TotalNoOfVisits,0) as Act_MFAT,
  
      coalesce(F.TotalNoOfVisits,0) as Act_SATAM,
      coalesce(G.TotalNoOfVisits,0) as Act_SATPM,
      coalesce(H.TotalNoOfVisits,0) as Act_SATEV,  

   
   /** try and trap duplicates **/
   ROW_NUMBER() OVER ( PARTITION BY MonthStart, Street_Name 
                       ORDER BY  MonthStart, Street_Name DESC) row_num
     
   FROM cteCalendarSummary     as A
  LEFT JOIN On_Street_Summary as B ON A.MonthStart = B.FinMonthStartDate 
                                    AND A.Street_Name = B.street AND B.TimeZone = 'MFAM'
   LEFT JOIN On_Street_Summary as C ON A.MonthStart = C.FinMonthStartDate 
                                    AND A.Street_Name = C.street AND C.TimeZone = 'MFPM'
   LEFT JOIN On_Street_Summary as D ON A.MonthStart = D.FinMonthStartDate 
                                    AND A.Street_Name = D.street AND D.TimeZone = 'MFEV' 
   LEFT JOIN On_Street_Summary as E ON A.MonthStart = E.FinMonthStartDate 
                                    AND A.Street_Name = E.street AND E.TimeZone = 'MFAT'  
   /** Saturday **/  
  
  LEFT JOIN On_Street_Summary as F ON A.MonthStart = F.FinMonthStartDate 
                                    AND A.Street_Name = F.street AND F.TimeZone = 'SATAM'
   LEFT JOIN On_Street_Summary as G ON A.MonthStart = G.FinMonthStartDate 
                                    AND A.Street_Name = G.street AND G.TimeZone = 'SATPM'
   LEFT JOIN On_Street_Summary as H ON A.MonthStart = H.FinMonthStartDate 
                                    AND A.Street_Name = H.street AND H.TimeZone = 'SATEV'
   ORDER BY A.MonthStart)
   
/******************************************************************************
Output the data 
*******************************************************************************/
SELECT 
   Month, Street_Name, CPZ, cpzname, 
   MFAM, 
   MFPM, 
   MFEV, 
   MFAT, 
   SATAM, 
   SATPM, 
   SATEV,
   Act_MFAM, Act_MFPM, Act_MFEV, Act_MFAT, Act_SATAM, Act_SATPM, Act_SATEV,
   
   current_timestamp() as ImportDateTime,
   
    replace(cast(current_date() as string),'-','') as import_date,
    
   -- Add the Import date
   cast(Year(current_date) as string)  as import_year, 
   cast(month(current_date) as string) as import_month, 
   cast(day(current_date) as string)   as import_day
   
FROM Display_Data
WHERE row_num = 1

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_ceo_on_street": AmazonS3_node1633593851886,
        "ceo_beat_visit_requirements": AmazonS3_node1633594330463,
        "ceo_visit_req_timings": AmazonS3_node1633593610551,
        "calendar": AmazonS3_node1632912445458,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Deployment_Target_Details/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Deployment_Target_Details",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
