 # This is a template for prototyping jobs. It loads the latest data from S3 using the Glue catalogue, performs an empty transformation, and writes the result to a target location in S3.
 # Before running your job, go to the Job Details tab and customise:
    # - the role Glue should use to run the job (it should match the department where the data is stored - if not, you will get permissions errors)
    # - the temporary storage path (same as above)
    # - the job parameters (replace the template values coming from the Terraform with real values)

import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import *
import pyspark.sql.functions as F
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.



# Function to ensure we only return the lates snapshot
def get_latest_snapshot(df):
    
   df = df.where(col('snapshot_date') == df.select(max('snapshot_date')).first()[0])
   return df



# Creates a function that removes any columns that are entirely null values - useful for large tables


def drop_null_columns(df):
  
    _df_length = df.count()
    null_counts = df.select([F.count(F.when(F.col(c).isNull(), c)).alias(c) for c in df.columns]).collect()[0].asDict()
    to_drop = [k for k, v in null_counts.items() if v >= _df_length]
    df = df.drop(*to_drop)
    
    return df

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_table2 = get_glue_env_var('source_catalog_table2','')
    source_catalog_table3 = get_glue_env_var('source_catalog_table3','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
    s3_bucket_target2 = get_glue_env_var('s3_bucket_target2', '')
    s3_bucket_target3 = get_glue_env_var('s3_bucket_target3', '')
 
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
        table_name = source_catalog_table
        # if the source data IS partitionned by import_date and there is a lot of historic data there that you don't need, consider using a pushdown predicate to only load a few days worth of data and speed up the job   
        # pushdown_predicate = create_pushdown_predicate('import_date', 2)
    )
    data_source2 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table2
    )
    
    data_source3 = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_catalog_table3
    )

    # If the source data is NOT partitioned by import_date, create the necessary import_ columns now and populate them with today's date so the result data gets partitioned as per the DP standards. 
    # Clarification: You normally won't use this if you have used pushdown_predicate and/or get_latest_partition earlier (unless you have dropped or renamed the import_ columns of the source data and want fresh dates to partition the result by processing date)
    # df = add_import_time_columns(df)

## Data processing Starts
    
    # Define Mappings
    # Create Dictionary for mappings - similar to mapping load in Qlik

        
    
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


    
# Load Tables

# Load Decision Levels Table

# convert to a data frame
    df = data_source.toDF()
    df = get_latest_snapshot(df)

# Drop Columns containing Only Nulls 
# df = drop_null_columns(df)

# Rename id column
    df = df.withColumnRenamed("id","decision_level_id") \
           .withColumnRenamed("name","decision_level") 

# Keep relevant columns

    df = df.select("decision_level_id",
                   "committee",
                   'last_updated',
                   'last_updated_by',
                   'decision_level',
                   'import_date',
                   'import_day',
                   'import_month',
                   'import_year',
                   'import_datetime',
                   'import_timestamp',
                   'snapshot_date')

# Create Calculated Fields for Reporting

    df = df.withColumn('counter_decision_level', lit(1))
    df = df.withColumn("flag_delegated",when(df.decision_level == "Delegated",1).otherwise(0))

# df.printSchema()


# Load Decision Types Table


# convert to a data frame
    df2 = data_source2.toDF()
    df2 = get_latest_snapshot(df2)
    
    df2 = df2.withColumnRenamed("id","decision_type_id") \
           .withColumnRenamed("name","decision_type")  \
           .withColumnRenamed("exacom_code","decision_exacom_code")

# Keep relevant columns

    df2 = df2.select("decision_type_id",
                   "approval_decision",
                   'last_updated',
                   'last_updated_by',
                   'decision_type',
                   'decision_exacom_code',  
                   'withdrawal',
                   'refusal_decision',
                   'import_date',
                   'import_day',
                   'import_month',
                   'import_year',
                   'import_datetime',
                   'import_timestamp',
                   'import_datetime',
                   'snapshot_date')

# Create Calculated Fields for Reporting

    df2 = df2.withColumn('counter_decision_type', lit(1))
    df2 = df2.withColumn("flag_dec_withdrawn",when(df2.decision_exacom_code == "Withdrawn",1).otherwise(0))
    df2 = df2.withColumn("flag_dec_granted",when(df2.decision_exacom_code == "Granted",1).otherwise(0))
    df2 = df2.withColumn("flag_dec_refused",when(df2.decision_exacom_code == "Refused",1).otherwise(0))

    
 ## Load PS Codes   
    

# convert to a data frame
    df3 = data_source3.toDF()

# drop old snapshots

    df3 = get_latest_snapshot(df3)



    df3 = df3.withColumnRenamed("id","ps_development_code_id") \
             .withColumnRenamed("name","development_type")

# Keep Only Relevant Columns
    df3 = df3.select("ps_development_code_id",
                     "expiry_days",
                     'major',
                     'minor',
                     'exclude_from_stat_returns',
                     'import_date',
                     'import_day',
                     'import_month',
                     'import_year',
                     'import_datetime',
                     'import_timestamp',
                     'import_datetime',
                     'snapshot_date',
                     'development_type')

    df3 = df3.withColumn("dev_type", col("development_type"))
    df3 = df3.replace(to_replace=mapDev, subset=['dev_type'])

# Create Calculated Fields for Reporting

    df3 = df3.withColumn('counter_ps_code', lit(1))



    # Transform data using the fuctions defined outside the main block
   






    
## Data Processing Ends    
    

    
    
    
    # Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(df, glueContext, "target_data_to_write")
    dynamic_frame2 = DynamicFrame.fromDF(df2, glueContext, "target_data_to_write")
    dynamic_frame3 = DynamicFrame.fromDF(df3, glueContext, "target_data_to_write")

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")
        
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame2,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target2, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")
        
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame3,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target3, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")    
        
        
        

    job.commit()
