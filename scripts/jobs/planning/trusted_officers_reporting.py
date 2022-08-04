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


    
# Load Tables

 

# Load Officers Table

    # convert to a data frame
    df = data_source.toDF()
    
    # Rename columns
    df = df.withColumnRenamed("id","officer_id") \
           .withColumnRenamed("forename","officer_forename") \
           .withColumnRenamed("surname","officer_surname")
           
    # Specify Columns to Keep
    
    df = df.select('officer_id',
                   "officer_forename",
                   "officer_surname",
                   'username',
                   'email',
                   'mobile',
                   'phone',
                   'job_title',
                   'import_date',
                   'import_day',
                   'import_month',
                   'import_year',
                   'snapshot_date')       

    # Return only latest snapshot
    
    df = get_latest_snapshot(df)
    
    # Drop Columns containing Only Nulls 
    # df = drop_null_columns(df)
    
    
    # Create Calculated Fields for Reporting
    
    df = df.withColumn('counter_officer', lit(1))
    df = df.withColumn('officer_name',concat(trim(col('officer_forename')),lit(" "),trim(col('officer_surname'))))
    
    # df.printSchema()


# Load User Teams Map Table
    
    
    
    # convert to a data frame
    df2 = data_source2.toDF()

    # drop old snapshots
    
    df2 = get_latest_snapshot(df2)
    
    # Rename Relevant Columns
    # df2 = df2.withColumnRenamed("user_id","officer_id") 

    # Keep Only Relevant Columns
    df2 = df2.select("user_id",
                     "user_team_id")



## Load User Teams Table
    

    # convert to a data frame
    df3 = data_source3.toDF()

    
    # drop old snapshots
    
    df3 = get_latest_snapshot(df3)
    
    df3 = df3.withColumnRenamed("id","team_id") \
             .withColumnRenamed("name","team_name") \
             .withColumnRenamed("description","team_description")
    
    # Keep Only Relevant Columns
    df3 = df3.select("team_id","team_name",'team_description','location')





    # Transform data using the fuctions defined outside the main block
   

    # Join
    
    df2 = df2.join(df3,df2.user_team_id ==  df3.team_id,"left")
    df = df.join(df2,df.officer_id ==  df2.user_id,"left")
    df = df.drop("team_id","user_id")
    




    
## Data Processing Ends    
    

    
    
    
# Convert data frame to dynamic frame 
    dynamic_frame = DynamicFrame.fromDF(df, glueContext, "target_data_to_write")


# Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dynamic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": s3_bucket_target, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")
        
        
        
        

    job.commit()

   
