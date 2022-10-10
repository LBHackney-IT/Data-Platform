import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var
environment = get_glue_env_var("environment")

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)

SqlQuery0 = '''
/**************************************************************************************************************
Correspondance Reps & Appeals Response period

Number Summary response to parking representations for GDS by Quarters

12/08/2021 - create the query
****************************************************************************************************************/
WITH Postal_Response as (
SELECT 
     ticketserialnumber, 
     cast(substr(date_received, 1, 10) as date)         as date_received,
     cast(substr(response_generated_at, 1, 10) as date) as response_generated_at,
     -- concat(substr(Cast(date_received as varchar(10)),1, 7), '-01') as MonthYear,
     concat('Q',Cast(extract(quarter from date_received) as varchar(2)),' ',cast(extract(year from date_received)as varchar(4)))    AS date_received_quarter,
     concat(extract(year from date_received),extract(quarter from date_received))    AS quarter_sort,
     Datediff(cast(substr(response_generated_at, 1, 10) as date),
                        cast(substr(date_received, 1, 10) as date)) as ResponseDays 
from liberator_pcn_ic
where import_Date = (Select MAX(import_date) from liberator_pcn_ic) 
AND date_received != '' AND response_generated_at != ''
AND length(ticketserialnumber) = 10 AND 
Serviceable IN ('Challenges','Key worker','Removals','TOL','Charge certificate','Representations'))

SELECT date_received_quarter, quarter_sort, cast(count(*) as decimal) as TotalResponded,
       SUM(Case 
                When ResponseDays <= 5 Then 1
                ELSE 0
             END) as LessThanEqual5,
       SUM(Case 
                When ResponseDays >= 6 AND ResponseDays <=14 Then 1
                ELSE 0
             END) as SixToFourteen,
       SUM(Case 
                When ResponseDays >= 15 AND ResponseDays <=47 Then 1
                ELSE 0
             END) as FifteenToFortySeven,
       SUM(Case 
                When ResponseDays >= 48 AND ResponseDays <=56 Then 1
                ELSE 0
             END) as FortyEightToFiftySix,
       SUM(Case 
                When ResponseDays > 56 Then 1
                ELSE 0
             END) as GTFiftySix,
       SUM(Case 
                When ResponseDays <= 56 Then 1
                ELSE 0
             END) as kpiTotFiftySixLess,
       SUM(Case 
                When ResponseDays <= 14 Then 1
                ELSE 0
             END) as kpiTotFourteenLess,
             
    /*** Control Dates ***/       
    substr(Cast(current_date as varchar(10)),1, 4) as import_year,
    substr(Cast(current_date as varchar(10)),6, 2) as import_month,
    substr(Cast(current_date as varchar(10)),9, 4) as import_day,
    Cast(current_date as varchar(10))              as import_date
    
FROM Postal_Response
GROUP BY date_received_quarter,quarter_sort
Order by quarter_sort Desc

'''

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_pcn_ic", transformation_ctx = "DataSource0"]
## @return: DataSource0
## @inputs: []
DataSource0 = glueContext.create_dynamic_frame.from_catalog(database = "dataplatform-" + environment + "-liberator-raw-zone", table_name = "liberator_pcn_ic", transformation_ctx = "DataSource0")
## @type: SqlCode
## @args: [sqlAliases = {"liberator_pcn_ic": DataSource0}, sqlName = SqlQuery0, transformation_ctx = "Transform0"]
## @return: Transform0
## @inputs: [dfc = DataSource0]
Transform0 = sparkSqlQuery(glueContext, query = SqlQuery0, mapping = {"liberator_pcn_ic": DataSource0}, transformation_ctx = "Transform0")
## @type: DataSink
## @args: [connection_type = "s3", catalog_database_name = "dataplatform-" + environment + "-liberator-refined-zone", format = "glueparquet", connection_options = {"path": "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Rep_and_Appeals_Corresp_KPI_GDS_Summary_QTR/", "partitionKeys": ["import_year" ,"import_month" ,"import_day" ,"import_date"], "enableUpdateCatalog":true, "updateBehavior":"UPDATE_IN_DATABASE"}, catalog_table_name = "parking_reps_and_appeals_correspondance_kpi_gds_summary_qtr", transformation_ctx = "DataSink0"]
## @return: DataSink0
## @inputs: [frame = Transform0]
DataSink0 = glueContext.getSink(path = "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Rep_and_Appeals_Corresp_KPI_GDS_Summary_QTR/", connection_type = "s3", updateBehavior = "UPDATE_IN_DATABASE", partitionKeys = ["import_year","import_month","import_day","import_date"], enableUpdateCatalog = True, transformation_ctx = "DataSink0")
DataSink0.setCatalogInfo(catalogDatabase = "dataplatform-" + environment + "-liberator-refined-zone",catalogTableName = "parking_reps_and_appeals_correspondance_kpi_gds_summary_qtr")
DataSink0.setFormat("glueparquet")
DataSink0.writeFrame(Transform0)

job.commit()