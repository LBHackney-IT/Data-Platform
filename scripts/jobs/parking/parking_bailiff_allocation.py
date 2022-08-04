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
AmazonS3_node1625732038443 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="bailiffreturn_marston",
    transformation_ctx="AmazonS3_node1625732038443",
)

# Script generated for node S3 bucket
S3bucket_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="bailiffreturn_equita",
    transformation_ctx="S3bucket_node1",
)

# Script generated for node Amazon S3
AmazonS3_node1625732651466 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="bailiffreturn_newlyn",
    transformation_ctx="AmazonS3_node1625732651466",
)

# Script generated for node Amazon S3
AmazonS3_node1625732674746 = glueContext.create_dynamic_frame.from_catalog(
    database="parking-raw-zone",
    table_name="bailiffreturn_whyte",
    transformation_ctx="AmazonS3_node1625732674746",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/*************************************************************************************************************************
Bailiff Allocation

The SQL builds the Bailiff allocation summary data

07/07/2021 - Create SQL

*************************************************************************************************************************/

/*** Find the latest Created Date, in each of the Bailiff files ***/
WITH MAX_Date as (
SELECT MAX(Created_Date) as MaxDate
FROM bailiffreturn_marston as A
where A.import_Date = (Select MAX(import_date) from bailiffreturn_marston)
UNION ALL
SELECT MAX(Created_Date) 
FROM bailiffreturn_equita as B
where B.import_Date = (Select MAX(import_date) from bailiffreturn_equita)
UNION ALL
SELECT MAX(Created_Date) 
FROM bailiffreturn_newlyn as C
where C.import_Date = (Select MAX(import_date) from bailiffreturn_newlyn)
UNION ALL
SELECT MAX(Created_Date) 
FROM bailiffreturn_whyte as D
where D.import_Date = (Select MAX(import_date) from bailiffreturn_whyte)),

/*** Collect the latest Bailiff data ***/
BailiffReturn AS (
SELECT 'Marston' as EA
      ,Status as Status_Code
      ,Status_description
      ,CAST(Warrant_Date as date)                                AS Warrant_Date
      ,CAST(CONCAT(substring(Warrant_Date, 1, 8), '01') as date) AS MonthYear
      ,CAST(PCN_Fee as double)                                   AS PCN_Fee
      
      /*** check the payments, if payment greater than the min created date, ignore the payments */
      ,CASE
         WHEN Payment_Date != 'NULL' AND Payment_Date > (SELECT MIN(MaxDate) FROM MAX_Date) THEN 0 
         ELSE
            CASE When Amount_Remitted_to_Client = 'NULL' Then 0 
            ELSE CAST(Amount_Remitted_to_Client as double) 
            END 
       END                                                       AS Amount_Remitted_to_Client
      /** Format the remaining balence from string **/
      ,CASE When Client_Balance_Remaining = 'NULL' Then 0 ELSE 
													CAST(Client_Balance_Remaining as double) END as Client_Balance_Remaining
      /* Format the Dates */
	  ,CASE
	     WHEN Payment_Date != 'NULL' Then CAST(Payment_Date as date)
	     ELSE CAST(NULL as date)
	   END as Payment_Date
	  ,CASE
	     WHEN Payment_Date != 'NULL' Then CONCAT(substring(Payment_Date,1,5),
                                           CAST(extract(week from CAST(Payment_Date as date)) as varchar(2)))
	     ELSE ''
	   END as PaidYearWeek
       /* Status Flags */
	  ,CASE When Status = 'D' then 1 else 0 end as Returned
	  ,CASE When Status = 'D' then 0 else 1 end as NotReturned
FROM bailiffreturn_marston as A
where A.import_Date = (Select MAX(import_date) from bailiffreturn_marston) AND 
      Created_Date = (Select MAX(Created_Date) FROM bailiffreturn_marston) AND
      Warrant_Date Between '2021-03-01' AND (SELECT MIN(MaxDate) FROM MAX_Date) 
  
UNION ALL
SELECT 'Equita' as EA
      ,Status
      ,Status_description
      ,CAST(Warrant_Date as date)                                AS Warrant_Date
      ,CAST(CONCAT(substring(Warrant_Date, 1, 8), '01') as date) AS MonthYear
      ,CAST(PCN_Fee as double)                                   AS PCN_Fee
      
      /*** check the payments, if payment greater than the min created date, ignore the payments */
      ,CASE
         WHEN PaymentDate != 'NULL' AND PaymentDate > (SELECT MIN(MaxDate) FROM MAX_Date) THEN 0 
         ELSE
            CASE When Amount_Remitted_to_Client = 'NULL' Then 0 
            ELSE CAST(Amount_Remitted_to_Client as double) 
            END 
       END                                                       AS Amount_Remitted_to_Client
      ,CASE When Client_Balance_Remaining = 'NULL' Then 0 ELSE 
													CAST(Client_Balance_Remaining as double) END as Client_Balance_Remaining
      /* Format the Dates */
	  ,CASE
	     WHEN PaymentDate != 'NULL' Then CAST(PaymentDate as date)
	     ELSE CAST(NULL as date)
	   END as PaymentDate
	  ,CASE
	     WHEN PaymentDate != 'NULL' Then CONCAT(substring(PaymentDate,1,5),
                                           CAST(extract(week from CAST(PaymentDate as date)) as varchar(2)))
	     ELSE ''
	   END as PaidYearWeek
       /* Status Flags */
	  ,CASE When Status = 'D' then 1 else 0 end as Returned
	  ,CASE When Status = 'D' then 0 else 1 end as NotReturned
FROM bailiffreturn_equita as A
where A.import_Date = (Select MAX(import_date) from bailiffreturn_equita) AND
      Created_Date = (Select MAX(Created_Date) FROM bailiffreturn_equita) AND
      Warrant_Date Between '2021-03-01' AND (SELECT MIN(MaxDate) FROM MAX_Date) 
  
UNION ALL
SELECT 'Newlyn' as EA
      ,Status_code
      ,Status_description
      ,CAST(Warrant_Date as date)                                AS Warrant_Date
      ,CAST(CONCAT(substring(Warrant_Date, 1, 8), '01') as date) AS MonthYear
      ,CAST(PCN_Fee as double)                                   AS PCN_Fee
      
      /*** check the payments, if payment greater than the min created date, ignore the payments */
      ,CASE
         WHEN Payment_Date != 'NULL' AND Payment_Date > (SELECT MIN(MaxDate) FROM MAX_Date) THEN 0 
         ELSE
            CASE When Amount_Remitted_to_Client = 'NULL' Then 0 
            ELSE CAST(Amount_Remitted_to_Client as double) 
            END 
       END                                                       AS Amount_Remitted_to_Client
      ,CASE When Client_Balance_Remaining = 'NULL' Then 0 ELSE 
													CAST(Client_Balance_Remaining as double) END as Client_Balance_Remaining
      /* Format the Dates */
	  ,CASE
	     WHEN Payment_Date != 'NULL' Then CAST(Payment_Date as date)
	     ELSE CAST(NULL as date)
	   END as PaymentDate
	  ,CASE
	     WHEN Payment_Date != 'NULL' Then CONCAT(substring(Payment_Date,1,5),
                                           CAST(extract(week from CAST(Payment_Date as date)) as varchar(2)))
	     ELSE ''
	   END as PaidYearWeek
       /* Status Flags */
	  ,CASE When Status_code = 'D' then 1 else 0 end as Returned
	  ,CASE When Status_code = 'D' then 0 else 1 end as NotReturned
FROM bailiffreturn_newlyn as A
where A.import_Date = (Select MAX(import_date) from bailiffreturn_newlyn) AND
      Created_Date = (Select MAX(Created_Date) FROM bailiffreturn_newlyn) AND
      Warrant_Date Between '2021-03-01' AND (SELECT MIN(MaxDate) FROM MAX_Date) 
UNION ALL
SELECT 'Whyte' as EA
      ,Status_code
      ,Status_description
      ,CAST(Warrant_Date as date)                                AS Warrant_Date
      ,CAST(CONCAT(substring(Warrant_Date, 1, 8), '01') as date) AS MonthYear
      ,CAST(PCN_Fee as double)                                   AS PCN_Fee
      
      /*** check the payments, if payment greater than the min created date, ignore the payments */
      ,CASE
         WHEN Payment_Date != 'NULL' AND Payment_Date > (SELECT MIN(MaxDate) FROM MAX_Date) THEN 0 
         ELSE
            CASE When Amount_Remitted_to_Client = 'NULL' Then 0 
            ELSE CAST(Amount_Remitted_to_Client as double) 
            END 
       END                                                       AS Amount_Remitted_to_Client
      ,CASE When Client_Balance_Remaining = 'NULL' Then 0 ELSE 
													CAST(Client_Balance_Remaining as double) END as Client_Balance_Remaining
      /* Format the Dates */
	  ,CASE
	     WHEN Payment_Date != 'NULL' Then CAST(Payment_Date as date)
	     ELSE CAST(NULL as date)
	   END as PaymentDate
	  ,CASE
	     WHEN Payment_Date != 'NULL' Then CONCAT(substring(Payment_Date,1,5),
                                           CAST(extract(week from CAST(Payment_Date as date)) as varchar(2)))
	     ELSE ''
	   END as PaidYearWeek
       /* Status Flags */
	  ,CASE When Status_code = 'D' then 1 else 0 end as Returned
	  ,CASE When Status_code = 'D' then 0 else 1 end as NotReturned
FROM bailiffreturn_whyte as A
where A.import_Date = (Select MAX(import_date) from bailiffreturn_whyte) AND
      Created_Date = (Select MAX(Created_Date) FROM bailiffreturn_whyte) AND
      Warrant_Date Between '2021-03-01' AND (SELECT MIN(MaxDate) FROM MAX_Date)),

/*************************************************************************************************************************
Process the Data collected, summerise to Michael W's requirements
*************************************************************************************************************************/
ProcessBailiffReturn as (
select EA, MonthYear, count(*) as TotalWarrants, Sum(Returned) as ReturnedWarrant, 
    SUM(NotReturned)                                                                                        AS AcceptedWarrants,
	CAST(SUM(Case When Status_Code != 'D' then PCN_Fee else 0 end) as decimal(11,2))                        AS AcceptedTotalValue,
	CAST(SUM(Case When Status_Code != 'D' then Amount_Remitted_to_Client else 0 end) as decimal(11,2))      AS TotalIncome,
	CAST(SUM(Case When Status_Code IN ('B','C','H','PP','V','Z') Then PCN_Fee else 0 end) as decimal(11,2)) AS Excluded,
	SUM(Case When Status_Code IN ('B','C','H','PP','V','Z') Then 1 else 0 end)				                AS ExcludedCount,
	SUM(Case When Status_Code not IN ('B','C','H','PP','V','Z') Then PCN_Fee else 0 end)	                AS WarrantsValue,
	SUM(Case When Status_Code IN ('A','AH','AT','AP') Then PCN_Fee else 0 end)				                AS Live,
  

    CAST((SUM(Case When Status_Code != 'D' then Amount_Remitted_to_Client else 0 end) / 
        SUM(Case When Status_Code not IN ('B','C','H','PP','V','Z') Then PCN_Fee else 0 end) * 100) as decimal(11,2)) AS RecoveryRate
   
FROM BailiffReturn
group by EA, MonthYear
Order by EA, MonthYear),

Warrant_totals as (
      SELECT MonthYear, SUM(TotalWarrants) as Monthly_W_Total FROM ProcessBailiffReturn
      Group By MonthYear)


SELECT 
    A.MonthYear, 
    A.EA, 
    A.TotalWarrants, 
    A.ExcludedCount,
    cast(A.live as decimal(11,2)) as Live,
	CAST((cast(A.TotalWarrants as double)/B.Monthly_W_Total)* 100 as decimal(11,2)) as Percentage_Allocation_of_Warrants_to_EA,
	CASE 
       When A.ExcludedCount > 0 THEN CAST((cast(A.ExcludedCount as double)/A.TotalWarrants) * 100 as decimal(11,2))
       Else 0 
    End as Percentage_Excluded_by_EA,
    
    current_date() as import_date,
    
    current_timestamp() as ImportDateTime,
    
    -- Add the Import date
       Year(current_date) as import_year, month(current_date) as import_month, day(current_date) as import_day 
from ProcessBailiffReturn as A
INNER JOIN Warrant_totals as B ON A.MonthYear = B.MonthYear
Order by Monthyear, EA

"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={
        "bailiffreturn_marston": AmazonS3_node1625732038443,
        "bailiffreturn_equita": S3bucket_node1,
        "bailiffreturn_newlyn": AmazonS3_node1625732651466,
        "bailiffreturn_whyte": AmazonS3_node1625732674746,
    },
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Bailiff_Allocation/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Bailiff_Allocation",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
