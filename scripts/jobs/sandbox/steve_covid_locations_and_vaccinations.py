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
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, create_pushdown_predicate, add_import_time_columns, PARTITION_KEYS

# Define the functions that will be used in your job (optional). For Production jobs, these functions should be tested via unit testing.
def someDataProcessing(locations_df, vaccinations_df):
    # do something
    locations_df_renamedLocation = locations_df.withColumnRenamed('location','country')
    vaccinations_df_renamedLocation = vaccinations_df.withColumnRenamed('location','country')

    locations_df_renamedLocation = locations_df_renamedLocation.withColumn('last_observation_date',  F.to_date('last_observation_date', "yyyy-mm-dd"))

    join_df = locations_df_renamedLocation.join(vaccinations_df_renamedLocation, 'country', 'left')

    return join_df

# The block below is the actual job. It is ignored when running tests locally.
if __name__ == "__main__":
    
    # read job parameters
    args = getResolvedOptions(sys.argv, ['JOB_NAME'])
    source_locations_table = get_glue_env_var('source_locations_table', '')
    source_vaccinations_table = get_glue_env_var('source_vaccinations_table', '')
    source_catalog_database = get_glue_env_var('source_catalog_database', '')
    target_bucket = get_glue_env_var('s3_bucket_target', '')
 
    # start the Spark session and the logger
    glueContext = GlueContext(SparkContext.getOrCreate()) 
    logger = glueContext.get_logger()
    job = Job(glueContext)
    job.init(args['JOB_NAME'], args)

    # Log something. This will be ouput in the logs of this Glue job [search in the Runs tab: all logs>xxxx_driver]
    logger.info(f'The job is starting. The source tables are {source_catalog_database}.{source_locations_table} and {source_catalog_database}.{source_vaccinations_table}')


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

    # only keep the latest imported data
    # dont need >> df = get_latest_partitions(df)

    # Transform data using the fuctions defined outside the main block
    df = someDataProcessing(locations_df, vaccinations_df)
    
    # If the source data was NOT partitioned by import_date, you can add create time columns now (you'll never use statements line 46 and 59 in the same job)
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

   
