import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS

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
environment = get_glue_env_var("environment")

# Script generated for node parking_raw_zone - parking_parking_ops_db_defects_mgt
parking_raw_zoneparking_parking_ops_db_defects_mgt_node1658997944648 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    push_down_predicate="  to_date(import_date, 'yyyyMMdd') >= date_sub(current_date, 7)",
    table_name="parking_parking_ops_db_defects_mgt",
    transformation_ctx="parking_raw_zoneparking_parking_ops_db_defects_mgt_node1658997944648",
)

# Script generated for node SQL
SqlQuery0 = """
/*********************************************************************************
Parking_Defect_MET_FAIL_Monthly_Format

Temp SQL that formats the defect managment records For pivot report

18/11/2022 - Create Query
21/11/2022 - add sub/grand total(s) and calculate KPI percentage
22/11/2022 - change % calc to make it a decimal
28/07/2023 - add N/A records. Change closed date to a date made up
of sign off month and year NOT repair_date
*********************************************************************************/
With Defect_Basic as (
SELECT
    reference_no, 
    CAST(CASE
         When reported_date like '%0222%'Then   '2022-'||
                                                substr(reported_date, 7, 2)||'-'||
                                                substr(reported_date, 9, 2)   

        When reported_date like '%/%'Then   substr(reported_date, 7, 4)||'-'||
                                            substr(reported_date, 4, 2)||'-'||
                                            substr(reported_date, 1, 2)
        ELSE substr(cast(reported_date as string),1, 10)
    END as date) as reported_date,
    CAST(CASE
        When repair_date like '%/%'Then     substr(repair_date, 7, 4)||'-'||
                                            substr(repair_date, 4, 2)||'-'||
                                            substr(repair_date, 1, 2)
        ELSE substr(cast(repair_date as string),1, 10)
    END as date) as repair_date,
    CAST(CASE
        When repair_date like '%/%'Then     substr(repair_date, 7, 4)||'-'||
                                            substr(repair_date, 4, 2)||'-01'
        ELSE substr(cast(repair_date as string),1, 8)||'01'
    END as date) as Month_repair_date,
    CASE
        When category = 'post'  Then 'Post'
        Else category
    End as category, 
    date_wo_sent, 
    expected_wo_completion_date, target_turn_around, met_not_met, 
    full_repair_category, 
    issue, engineer,
    CASE
        When sign_off_year != '1899'        Then sign_off_month
        ELSE CASE
                When repair_date like '%/%'Then substr(repair_date, 4, 2)
                ELSE substr(cast(repair_date as string),6, 2)
            END 
    END as sign_off_month,   
    CASE
        When sign_off_year != '1899'        Then sign_off_year
        ELSE CASE
                When repair_date like '%/%'Then substr(repair_date, 7, 4)
                ELSE substr(cast(repair_date as string),1, 4)
            END 
    END as sign_off_year  
FROM parking_parking_ops_db_defects_mgt
WHERE import_date = (Select MAX(import_date) 
                                FROM parking_parking_ops_db_defects_mgt)
AND length(ltrim(rtrim(reported_date))) > 0 
AND met_not_met not IN ('#VALUE!','#N/A')
AND length(ltrim(rtrim(repair_date)))> 0),

/*** Tom has informed me that I cannot use the Repair date, but use the sigh off month & year
USe these fields to recreate Month_repair_date ***/
Defect as (
    SELECT
        reference_no, reported_date, repair_date,
        CAST( sign_off_year||'-'||sign_off_month||'-01' as date) as Month_repair_date,
        category, date_wo_sent, expected_wo_completion_date, target_turn_around, met_not_met, 
        full_repair_category, issue, engineer, sign_off_month, sign_off_year         
    FROM Defect_Basic),

/********************************************************************************
Obtain the category totals
********************************************************************************/
category_totals as (
SELECT
    Month_repair_date, category, met_not_met, count(*) as Total_Met_Fail
FROM Defect
WHERE repair_date >= 
    date_add(cast(substr(cast(current_date as string), 1, 8)||'01' as date),-365) AND
    met_not_met = 'Fail'
GROUP BY Month_repair_date, category, met_not_met
UNION ALL
SELECT
    Month_repair_date, category, met_not_met, count(*) as Total_Met_Fail
FROM Defect
WHERE repair_date >= 
    date_add(cast(substr(cast(current_date as string), 1, 8)||'01' as date),-365) AND
    met_not_met = 'Met'
GROUP BY Month_repair_date, category, met_not_met
UNION ALL
SELECT
    Month_repair_date, category, met_not_met, count(*) as Total_Met_Fail
FROM Defect
WHERE repair_date >= 
    date_add(cast(substr(cast(current_date as string), 1, 8)||'01' as date), -365) AND
    met_not_met = 'N/A'
GROUP BY Month_repair_date, category, met_not_met),
/********************************************************************************
Obtain the categories
********************************************************************************/
Categories as (
    SELECT distinct
        A.Month_repair_date, B.category
    FROM Defect as A
    CROSS JOIN (Select distinct category from Defect) as B
    Where length(B.category) > 0),

/********************************************************************************
Obtain and format the totals
********************************************************************************/
Category_Format as (
SELECT 
    A.Month_repair_date, A.category, 
    CASE When B.Total_Met_Fail is not NULL Then B.Total_Met_Fail Else 0 END as Total_Fail,
    CASE When C.Total_Met_Fail is not NULL Then C.Total_Met_Fail Else 0 END as Total_Met,
    CASE When D.Total_Met_Fail is not NULL Then D.Total_Met_Fail Else 0 END as Total_NA   
FROM Categories as A
LEFT JOIN category_totals as B ON A.Month_repair_date = B.Month_repair_date AND
                                    A.category = B.category AND B.met_not_met = 'Fail'
LEFT JOIN category_totals as C ON A.Month_repair_date = C.Month_repair_date AND
                                    A.category = C.category AND C.met_not_met = 'Met'                       
LEFT JOIN category_totals as D ON A.Month_repair_date = D.Month_repair_date AND
                                    A.category = D.category AND D.met_not_met = 'N/A'
WHERE A.Month_repair_date >= 
    date_add(cast(substr(cast(current_date as string), 1, 8)||'01' as date),-365)),

/********************************************************************************
Calculate the KPI %
********************************************************************************/
PDKPI as (
    SELECT 
        Month_repair_date,
        'Total_P&D_KPI_%' as Category,
        (cast((SUM(cast(Total_Met as double)) / 
                    SUM((Total_Met + Total_Fail))) as decimal(8,2))*100) as PD_KPI
    FROM Category_Format
WHERE category = 'P&D'
GROUP BY Month_repair_date),

SLPKPI as (
    SELECT 
        Month_repair_date,
        'Total_Signs_Lines_Posts_KPI_%' as Category,
        (cast((SUM(cast(Total_Met as double)) / 
            SUM((Total_Met + Total_Fail))) as decimal(8,2))*100) as Signs_Lines_Posts_KPI
    FROM Category_Format
WHERE category in ('Lines','Post','Signs')
GROUP BY Month_repair_date),
/********************************************************************************
Obtain the category totals & Grand totals
********************************************************************************/
catgory_totals as (
    SELECT 
        Month_repair_date, 
        category||' Total' as category,
        SUM(total_met_fail) as Total
    FROM category_totals
    GROUP BY Month_repair_date, category),

grand_totals as (
    SELECT 
        Month_repair_date, 
        SUM(total_met_fail) as Total
    FROM category_totals
    GROUP BY Month_repair_date),
/********************************************************************************
Format the output
********************************************************************************/
Format_Report as (
    SELECT
        Month_repair_date, category, 'Fail' as Total_Met_Fail, Total_Fail as Total
    FROM Category_Format
    UNION ALL
    SELECT
        Month_repair_date, category, 'Met' as Total_Met_Fail, Total_Met as Total
    FROM Category_Format
    UNION ALL
    SELECT
        Month_repair_date, category, 'N/A' as Total_Met_Fail, Total_NA as Total
    FROM Category_Format
    UNION ALL
    SELECT
        Month_repair_date, Category, '' as Total_Met_Fail, PD_KPI
    FROM PDKPI
    UNION ALL
    SELECT
        Month_repair_date, Category, '' as Total_Met_Fail, Signs_Lines_Posts_KPI
    FROM SLPKPI
    UNION ALL
    SELECT
        Month_repair_date, category, '' as Total_Met_Fail, Total
    FROM catgory_totals
    UNION ALL
    SELECT
       Month_repair_date, 'Total Grand' as category, '' as Total_Met_Fail, Total
    FROM grand_totals)
/********************************************************************************
Ouput data
********************************************************************************/
SELECT
    *,
    current_timestamp()                            as ImportDateTime,
    replace(cast(current_date() as string),'-','') as import_date,
    
    cast(Year(current_date) as string)    as import_year, 
    cast(month(current_date) as string)   as import_month, 
    cast(day(current_date) as string)     as import_day
FROM Format_Report












"""
SQL_node1658765472050 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "parking_parking_ops_db_defects_mgt": parking_raw_zoneparking_parking_ops_db_defects_mgt_node1658997944648
    },
    transformation_ctx="SQL_node1658765472050",
)

# Script generated for node Amazon S3
AmazonS3_node1658765590649 = glueContext.getSink(
    path="s3://dataplatform-"+environment+"-refined-zone/parking/liberator/Parking_Defect_MET_FAIL_Monthly_Format/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day", "import_date"],
    compression="snappy",
    enableUpdateCatalog=True,
    transformation_ctx="AmazonS3_node1658765590649",
)
AmazonS3_node1658765590649.setCatalogInfo(
    catalogDatabase="dataplatform-"+environment+"-liberator-refined-zone",
    catalogTableName="Parking_Defect_MET_FAIL_Monthly_Format",
)
AmazonS3_node1658765590649.setFormat("glueparquet")
AmazonS3_node1658765590649.writeFrame(SQL_node1658765472050)
job.commit()
