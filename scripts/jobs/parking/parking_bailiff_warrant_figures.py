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
AmazonS3_node1628173244776 = glueContext.create_dynamic_frame.from_catalog(
    database="dataplatform-" + environment + "-liberator-refined-zone",
    table_name="pcnfoidetails_pcn_foi_full",
    transformation_ctx="AmazonS3_node1628173244776",
)

# Script generated for node ApplyMapping
SqlQuery0 = """
/******************************************************************************************************************************
Parking_Bailiff_Warrant_Figures

This SQL creates the Warrant return figures on the basis of the following spec:-

1) Firstly identify all warrants issued to enforcement agents in the month in question. 
2) Exclude from this group PCNs that were cancelled
3) Then identify the payment status of the PCN - fully paid, partially paid, not paid
4) Produce a dataset for each month, that shows the number and % of the overall number of warrants (excluding cancelled) that fall into the above three categories. 


24/11/2021 - create SQL
25/11/2021 - Amend to add cancellation reasons from Alan, to identify PCN as NOT cancelled but NOT PAID
12/01/2022 - Amend the Cancellation reason list inline with an email from Nohaad
20/01/2022 - Amend the cancellation reason list after review by Michael Benn
******************************************************************************************************************************/
/*** Collect those PCNs that have a Warrant date ***/
WITH Bailiff_PCNs_Int as (
   SELECT 
      PCN, warrantissuedate as warrant_issued, 
      substr(cast(cast(warrant_issued as date) as string), 1, 8)||'01' as MonthYear, bailiff, pcn_canx_date,
      cancellationreason,
      lib_initial_debt_amount, lib_payment_received, lib_write_off_amount,
      /*** This is a flag that identifies those cancelled PCNs that should be treated and not cancelled? ***/
      CASE
          When cancellationreason IN ('Cancelled - Court Claim',
                                      'Closed file - Nulla Bona - No access',
                                      'Council Tennant - Sublet',
                                      'DEBT RECOVERY',
                                      'Gesture of Goodwill',
                                      'Gone away',
                                      'Gone Away-S100    ',
                                      'I - Insufficient Goods',
                                      'I - Unable to find effects',
                                      'I - Unable to Recover Debt',
                                      'Incomplete address',
                                      'L-Gone Away    ',
                                      'L-Not valid address',
                                      'L-PP-Sold    ',
                                      'L-Vulnerable    ',
                                      'M - Gone Away No Trace',
                                      'M - Goneaway',
                                      'M - Moved abroad',
                                      'N - Not Contacted',
                                      'New occupiers, no info on defaulters',
                                      'No trace',
                                      'Not applicable',
                                      'Not registered keeper',
                                      'Not resident in England and Wales',
                                      'Parents address - not resident',
                                      'Part paid no more expected',
                                      'Payment',
                                      'PCN written off',
                                      'PP - Persistent Evader',
                                      'PP -Part Payment Received - Persistent Evader',
                                      'Property Empty enquiries negative',
                                      'Property empty, fire damaged',
                                      'Refused Contact',
                                      'U - Unable to enforce',
                                      'U - Unable to Recover Debt',
                                      'Unenforceable',
                                      'Unsuccessful',
                                      'V - Vulnerable Group',
                                      'Vulnerable',
                                      'Vulnerable Debtor',
                                      'X - Warrant has expired') Then 1
          When pcn_canx_date is NULL                             Then 2
          ELSE 0
     END as Write_Off_Flag
   FROM pcnfoidetails_pcn_foi_full 
   WHERE import_Date = (Select MAX(import_date) from pcnfoidetails_pcn_foi_full) and
   length(cast(warrantissuedate as string)) > 0 ),

Bailiff_PCNs as (
   SELECT
      PCN, warrant_issued, 
      substr(cast(cast(warrant_issued as date) as string), 1, 8)||'01' as MonthYear,
      lib_initial_debt_amount, lib_payment_received, lib_write_off_amount,pcn_canx_date,cancellationreason,
  
      /*** Create the payment flag ***/
      CASE
         When Write_Off_Flag = 1                                                              Then 'Not Paid'
         When cast(lib_payment_received as double) = 0 AND 
              cast(lib_write_off_amount as double) = 0                                        Then 'Not Paid'
         When cast(lib_payment_received as double) = cast(lib_initial_debt_amount as double)  Then 'Paid'
         When cast(lib_payment_received as double) != cast(lib_initial_debt_amount as double) 
                        AND cast(lib_payment_received as double) != 0                         Then 'Part Payment'
      END as Payment_Status
  
   FROM Bailiff_PCNs_Int
   WHERE Write_Off_Flag != 0),

/*** Get the distinct Months ***/
Basic_Month as (
   SELECT distinct MonthYear
   FROM Bailiff_PCNs),

/*** Summerise the number of PCNs ***/
Summary_PCN as (
   SELECT
      MonthYear,
      Payment_Status,
      count(*) as No_of_Warrents

   FROM Bailiff_PCNs
   GROUP BY MonthYear,Payment_Status
   ORDER BY MonthYear, Payment_Status),
   
/*** Bring the data togather into a single record ***/
Merge_Month as (
   SELECT
      A.MonthYear as WarrantMonth,
      coalesce(B.No_of_Warrents,0) as Paid_Total,
      coalesce(C.No_of_Warrents,0) as Part_Paid_Total,
      coalesce(D.No_of_Warrents,0) as Not_Paid_Total,
   
      (coalesce(B.No_of_Warrents,0)+
       coalesce(C.No_of_Warrents,0)+
       coalesce(D.No_of_Warrents,0)) as Total_No_PCN

   from Basic_Month as A
   LEFT JOIN Summary_PCN as B ON A.MonthYear = B.MonthYear AND B.payment_status = 'Paid'
   LEFT JOIN Summary_PCN as C ON A.MonthYear = C.MonthYear AND C.payment_status = 'Part Payment'
   LEFT JOIN Summary_PCN as D ON A.MonthYear = D.MonthYear AND D.payment_status = 'Not Paid'
   order by A.MonthYear)
   
/*** Output the data and create a % figure for each of the Payment flags ***/
SELECT 
   A.*,
   round((cast(Paid_Total as double)/Total_No_PCN)*100,2)      as Paid_Total_Percentage,
   round((cast(Part_Paid_Total as double)/Total_No_PCN)*100,2) as Part_Paid_Total_Percentage,
   round((cast(Not_Paid_Total as double)/Total_No_PCN)*100,2)  as Not_Paid_Total_Percentage,
   
   current_timestamp() as ImportDateTime,
   
    replace(cast(current_date() as string),'-','') as import_date,
    
    -- Add the Import date
    Year(current_date)  as import_year, 
    month(current_date) as import_month, 
    day(current_date)   as import_day    
   
FROM Merge_Month as A
Order by A.WarrantMonth
"""
ApplyMapping_node2 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"pcnfoidetails_pcn_foi_full": AmazonS3_node1628173244776},
    transformation_ctx="ApplyMapping_node2",
)

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.getSink(
    path="s3://dataplatform-" + environment + "-refined-zone/parking/liberator/Parking_Bailiff_Warrant_Figures/",
    connection_type="s3",
    updateBehavior="UPDATE_IN_DATABASE",
    partitionKeys=["import_year", "import_month", "import_day"],
    enableUpdateCatalog=True,
    transformation_ctx="S3bucket_node3",
)
S3bucket_node3.setCatalogInfo(
    catalogDatabase="dataplatform-" + environment + "-liberator-refined-zone",
    catalogTableName="Parking_Bailiff_Warrant_Figures",
)
S3bucket_node3.setFormat("glueparquet")
S3bucket_node3.writeFrame(ApplyMapping_node2)
job.commit()
