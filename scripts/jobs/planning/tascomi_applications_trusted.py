# This is a template for prototyping jobs. It loads the latest data from S3 using the Glue catalogue, performs an empty transformation, and writes the result to a target location in S3.
 # Before running your job, go to the Job Details tab and customise:
    # - the role Glue should use to run the job (it should match the department where the data is stored - if not, you will get permissions errors)
    # - the temporary storage path (same as above)
    # - the job parameters (replace the template values coming from the Terraform with real values)

import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import *
import pyspark.sql.functions as F
from helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS_SNAPSHOT

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.

def get_latest_snapshot(df):
   df = df.where(F.col('snapshot_date') == df.select(max('snapshot_date')).first()[0])
   return df 


# Creates a function that clears the target folder in S3
def clear_target_folder(s3_bucket_target):
    s3 = boto3.resource('s3')
    folderString = s3_bucket_target.replace('s3://', '')
    bucketName = folderString.split('/')[0]
    prefix = folderString.replace(bucketName+'/', '')+'/'
    bucket = s3.Bucket(bucketName)
    bucket.objects.filter(Prefix=prefix).delete()
    return


# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_table2 = get_glue_env_var('source_catalog_table2','')
    source_catalog_table3 = get_glue_env_var('source_catalog_table3','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')


    # Load data from glue catalog
    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space = source_catalog_database,
        table_name = source_catalog_table,
        push_down_predicate = create_pushdown_predicate('snapshot_date', 3)
    )

    df = data_source.toDF()

    if not (df.rdd.isEmpty()) :

    ## Data processing Starts
        
        # If the source data IS partitionned by import_date, you have loaded several days but only need the latest version, use the get_latest_partitions() helper
        df = get_latest_snapshot(df)    
        
        # Rename id column
        df = df.withColumnRenamed("id","application_id")
        
        # Create Calculated Fields for Reporting Measures

        # Date Calculations
        
        df = df.withColumn('day_of_week', F.dayofweek(F.col('decision_issued_date'))) \
            .selectExpr('*', 'date_sub(decision_issued_date, day_of_week-2) as decision_report_week') \
            .withColumn('day_of_week', F.dayofweek(F.col('registration_date'))) \
            .selectExpr('*', 'date_sub(registration_date, day_of_week-2) as registration_report_week') \
            .withColumn('day_of_week', F.dayofweek(F.col('received_date'))) \
            .selectExpr('*', 'date_sub(received_date, day_of_week-2) as received_report_week') \
            .withColumn('export_date', F.date_sub(current_date(),1)) \
            .withColumn('days_received_to_decision', F.datediff('decision_issued_date','received_date')) \
            .withColumn('days_received_to_valid', F.datediff('valid_date','received_date')) \
            .withColumn('days_valid_to_registered', F.datediff('registration_date','valid_date')) \
            .withColumn('days_in_system', F.datediff('export_date','received_date')) \

        # Merge Dates to calculate correct expiry date

        df = df.withColumn('date_application_expiry', F.coalesce('extension_of_time_due_date','expiry_date')) \
        
        # Create Flags for reporting measures

        df = df.withColumn("flag_validated",when(df.valid_date.isNull(),0).otherwise(1)) \
        .withColumn("flag_decided",when(df.decision_issued_date.isNull(),0).otherwise(1)) \
        .withColumn("flag_extended",when(df.extension_of_time_due_date.isNull(),0).otherwise(1)) \
        .withColumn("flag_registered",when(df.registration_date.isNull(),0).otherwise(1)) \
        .withColumn("flag_ppa",when(df.ppa_decision_due_date.isNull(),0).otherwise(1)) \


        # Define Mappings
        # Create Dictionary for mappings - similar to mapping load in Qlik

        mapStage = {
                    '1': '1: RECEIPT/RECEIVED',
                    '2': '2: INVALID/INCOMPLETE',
                    '3': '3: VALID/COMPLETE',
                    '4': '4: CONSULTATION/PUBLICITY',
                    '5': '5: CONSULATION COMPLETE',
                    '6': '6: ASSESSMENT',
                    '7': '7: RECOMMENDATION',
                    '8': '8: COMMITTEE',
                    '9': '9: DETERMINATION REFERRED',
                    '10': '10: DECISION ISSUED',
                    '11': '11: UNDER APPEAL'}
            
        
        mapDev = {
                    '(E)Major Development (TDC)': 'Other',
                    '(E)Minor (Housing-Led) (PIP)': 'Other',
                    '(E)Minor (Housing-Led) (TDC)': 'Other',
                    '(E)Minor Gypsy and Traveller sites development': 'Minor',
                    '(E)Relevant Demolition In A Conservation Area (Other)': 'Other',
                    'Advertisements':'Other',
                    'All Others':'Other',
                    'Certificate of Lawful Development': 'Other',
                    'Certificates of Appropriate Alternative Development': 'Other',
                    'Certificates of Lawfuless of Proposed Works to Listed Buildings': 'Other',
                    'Change of use': 'Other',
                    'Conservation Area Consents': 'Other',
                    'Extended construction hours': 'Other',
                    'Householder': 'Other',
                    'Larger Household Extensions': 'Other',
                    'Listed Building Alterations': 'Other',
                    'Listed Building Consent to Demolish': 'Other',
                    'Major Dwellings': 'Major',
                    'Major Gypsy and Traveller sites development': 'Major',
                    'Major Industrial': 'Major',
                    'Major Office': 'Major',
                    'Major Retail': 'Major',
                    'Minerals': 'Other',
                    'Minor Industrial': 'Minor',
                    'Minor Office': 'Minor',
                    'Minor Residential': 'Minor',
                    'Minor Retail': 'Minor',
                    'Non-Material Amendments': 'Other',
                    'Not Required On Statutory Returns': 'Not Req. on Stat Returns',
                    'Notifications': 'Other',
                    'Office to Residential': 'Other',
                    'Other Major Developments': 'Major',
                    'Other Minor Developments': 'Minor',
                    'Prior notification - new dwellings': 'Other',
                    'Retail and Sui Generis Uses to Residential': 'Other',
                    'Storage or Distribution Centres to Residential': 'Other',
                    'To State-Funded School or Registered Nursery': 'Other'}
    
        # Apply Map to application stage field - first convert data types so they are both strings
        
        df = df.withColumn('application_stage_name', col('application_stage').cast('string'))
        df = df.replace(to_replace=mapStage, subset=['application_stage_name'])
        # Applications table is ready for joining

        ## Load Application Types Table
        data_source2 = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=source_catalog_table2,
            push_down_predicate = create_pushdown_predicate('snapshot_date', 3)
        )
               
        df2 = data_source2.toDF()
        df2 = get_latest_snapshot(df2)
        
        # Rename Relevant Columns
        
        df2 = df2.withColumnRenamed("name","application_type") \
                .withColumnRenamed("code","application_type_code")
                
        # Keep Only Relevant Columns
        
        df2 = df2.select("id","application_type","application_type_code")
        
        ## Load PS Codes   
        data_source3 = glueContext.create_dynamic_frame.from_catalog(
            name_space=source_catalog_database,
            table_name=source_catalog_table3,
            push_down_predicate = create_pushdown_predicate('snapshot_date', 3)
        )

        df3 = data_source3.toDF()
        df3 = get_latest_snapshot(df3)
        
        # Rename Relevant Columns
        
        df3 = df3.withColumnRenamed("id","ps_id") \
                .withColumnRenamed("name","development_type")
                
        # Keep Only Relevant Columns
        df3 = df3.select("ps_id","expiry_days",'development_type') 
        
        # Apply Dev Type Mapping
        df3 = df3.withColumn("dev_type", col("development_type"))
        df3 = df3.replace(to_replace=mapDev, subset=['dev_type'])
            

        ## Left Join Application Types and PS Development Codes onto Applications Table

        # Join

        df = df.join(df2,df.application_type_id ==  df2.id,"left")
        df = df.join(df3,df.ps_development_code_id ==  df3.ps_id,"left")
        
        # Create Additional Calculations that required fields from the joined tables
        
        df = df.selectExpr('*', 'date_add(received_date, expiry_days) as calc_expiry_date') \
        
        df = df.withColumn('current_expiry_date', F.coalesce('date_application_expiry','calc_expiry_date'))

        df = df.withColumn('flag_overdue_decided', when(df.decision_issued_date>df.current_expiry_date,1)
                                            .otherwise(0)) \
            .withColumn('flag_overdue_live', when(df.export_date>df.current_expiry_date,1)
                                            .otherwise(0)) \
            .withColumn('flag_overdue_registration', when(df.days_valid_to_registered>5,1)
                                                .otherwise(0)) \
            .withColumn('days_over_expiry', F.datediff('decision_issued_date','current_expiry_date'))
            
        # Add a Counter       
        
        df = df.withColumn('counter_application', lit(1))
        
        # Drop Duplicated Id columns created by the Join
        
        df = df.drop("ps_id","id", )
        
        ## Data Processing Ends    
        
        # Convert data frame to dynamic frame 
        dynamic_frame = DynamicFrame.fromDF(df, glueContext, "target_data_to_write")

        # wipe out the target folder in the trusted zone
        logger.info(f'clearing target bucket')
        clear_target_folder(s3_bucket_target)

        # Write the data to S3
        parquet_data = glueContext.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            format="parquet",
            connection_options={"path": s3_bucket_target, "partitionKeys":PARTITION_KEYS_SNAPSHOT},
            transformation_ctx="target_data_to_write")

    job.commit()
