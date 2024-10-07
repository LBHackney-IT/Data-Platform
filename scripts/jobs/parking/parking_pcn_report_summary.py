import sys

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

from scripts.helpers.helpers import create_pushdown_predicate, get_glue_env_var

environment = get_glue_env_var("environment")


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


SqlQuery0 = """
/*************************************************************************************************************************
Parking_PCN_Report_Summary

The SQL builds the PCN summary data, to get around the Google max number of records

12/07/2021 - Create SQL. Summerise the PCN's as Total No. issued to Debt Type (CEO, etc), Estate, etc UP to the End the
              previous month
*************************************************************************************************************************/
SELECT concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01') as IssueMonthYear,
       debttype as Debt_Type,
       CASE When street_location like '%Estate%' OR usrn like '%Z%' Then 1
            ELSE 0 END as Estate_Flag,
       CASE When Lib_Payment_Received != '0' Then 1 Else 0 END as Payment_Flag,
       count(*) as PCNs_Issued,

    date_format(CAST(CURRENT_TIMESTAMP AS timestamp), 'yyyy-MM-dd HH:mm:ss') AS ImportDateTime,
    date_format(current_date, 'yyyy') AS import_year,
    date_format(current_date, 'MM') AS import_month,
    date_format(current_date, 'dd') AS import_day,
    date_format(current_date, 'yyyyMMdd') AS import_date

FROM pcnfoidetails_pcn_foi_full as A
WHERE importdattime = (Select MAX(importdattime) from pcnfoidetails_pcn_foi_full) and warningflag = 0 and isvda = 0
      and isvoid = 0
      /*AND pcnissuedate <= date_add('day', -(CAST(substr(cast(current_date as varchar(10)), 9 ,2) as int)), current_date)*/

GROUP BY concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01'), debttype,
         CASE When street_location like '%Estate%' OR usrn like '%Z%' Then 1 ELSE 0 END,
         CASE When Lib_Payment_Received != '0' Then 1 Else 0 END
ORDER BY concat(substr(Cast(pcnissuedate as varchar(10)),1, 7), '-01'), debttype
"""

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ["JOB_NAME"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)
## @type: DataSource
## @args: [database = "dataplatform-" + environment + "-liberator-refined-zone", table_name = "pcnfoidetails_pcn_foi_full", transformation_ctx = "DataSource0"]
## @return: DataSource0
## @inputs: []
DataSource0 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="DataSource0",
    push_down_predicate=create_pushdown_predicate("import_date", 7),
)
## @type: SqlCode
## @args: [sqlAliases = {"pcnfoidetails_pcn_foi_full": DataSource0}, sqlName = SqlQuery0, transformation_ctx = "Transform0"]
## @return: Transform0
## @inputs: [dfc = DataSource0]
Transform0 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"pcnfoidetails_pcn_foi_full": DataSource0},
    transformation_ctx="Transform0",
)
## @type: DataSink
## @args: [connection_type = "s3", catalog_database_name = "dataplatform-" + environment + "-liberator-refined-zone", format = "glueparquet", connection_options = {"path": "s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_PCN_Report_Summary/", "partitionKeys": ["import_year" ,"import_month" ,"import_day"], "enableUpdateCatalog":true, "updateBehavior":"UPDATE_IN_DATABASE"}, catalog_table_name = "Parking_PCN_Report_Summary", transformation_ctx = "DataSink0"]
## @return: DataSink0
## @inputs: [frame = Transform0]
DataSink0 = glueContext.getSink(
    path="s3://dataplatform-"
    + environment
    + "-refined-zone/parking/liberator/Parking_PCN_Report_Summary/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    enableUpdateCatalog=True,
    transformation_ctx="DataSink0",
)
DataSink0.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_PCN_Report_Summary",
)
DataSink0.setFormat("glueparquet")
DataSink0.writeFrame(Transform0)

job.commit()
