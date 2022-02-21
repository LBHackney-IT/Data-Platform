import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
# import a few helper functions
from helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS

# Define the functions that will be used in your job (optional)
def someDataProcessing(df):
    # do something
    return df

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_catalog_table = get_glue_env_var('source_catalog_table','')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    target_bucket = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the log of this Glue job [all logs>xxxx_driver]
    logger.info(f'The job is starting. The source table is {source_catalog_database}.{source_catalog_table}')


    # Load data from glue catalog
    data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space = source_catalog_database,
        table_name = source_catalog_table,
        # if the source data is partitionned by import_date, use a pushdown predicate to optimise the job by only loading a few days worth of data  
        pushdown_predicate = create_pushdown_predicate('import_date', 2)
    )

    # convert dynamic frame to data frame
    df = data_source.toDF()

    # only keep the latest imported data
    df = get_latest_partitions(df)

    # Transform data using the fuctions defined outside the main block
    df = someDataProcessing(df)
    
    # Add import time columns with today's information (do not use if the source data is already partitionned by import_date)
    df = add_import_time_columns(df)
    
    # Convert data frame to dynamic frame 
    dyanmic_frame = DynamicFrame.fromDF(df, glueContext, "target_data_to_write")

    # Write the data to S3
    parquet_data = glueContext.write_dynamic_frame.from_options(
        frame=dyanmic_frame,
        connection_type="s3",
        format="parquet",
        connection_options={"path": target_bucket, "partitionKeys": PARTITION_KEYS},
        transformation_ctx="target_data_to_write")

    job.commit()