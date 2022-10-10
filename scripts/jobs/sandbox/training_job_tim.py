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
from pyspark.sql.functions import col, max, lit
from awsglue.dynamicframe import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.
def someDataProcessing(locations_df, vaccinations_df):
    # do something
    locations_df = locations_df.withColumnRenamed('location','country')
    vaccinations_df = vaccinations_df.withColumnRenamed('location','country')
    
    join_df = locations_df.join(vaccinations_df, 'country', 'left')

    return join_df
# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_locations_table = get_glue_env_var('source_locations_table', '')
    source_vaccinations_table = get_glue_env_var('source_vaccinations_table', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source table are {source_catalog_database}.{source_locations_table}, {source_catalog_database}.{source_vaccinations_table}')


    # Load data from glue catalog
    locations_data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_locations_table
    )
    vaccinations_data_source = glueContext.create_dynamic_frame.from_catalog(
        name_space=source_catalog_database,
        table_name=source_vaccinations_table
    )

    # convert dynamic frame to data frame
    locations_df = locations_data_source.toDF()
    vaccinations_df = vaccinations_data_source.toDF()

    # If the source data IS partitionned by import_date, you have loaded several days but only need the latest version, use the get_latest_partitions() helper
    # df = get_latest_partitions(df)

    # Transform data using the fuctions defined outside the main block
    df = someDataProcessing(locations_df, vaccinations_df)
    
    # If the source data is NOT partitioned by import_date, create the necessary import_ columns now and populate them with today's date so the result data gets partitioned as per the DP standards. 
    # Clarification: You normally won't use this if you have used pushdown_predicate and/or get_latest_partition earlier (unless you have dropped or renamed the import_ columns of the source data and want fresh dates to partition the result by processing date)
    # df = add_import_time_columns(df)
    
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

   
