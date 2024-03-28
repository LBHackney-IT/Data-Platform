import sys
import boto3
import time
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql import SparkSession, Row

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, PARTITION_KEYS
from scripts.helpers.database_ingestion_helpers import get_all_database_tables, update_table_ingestion_details

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
spark_session = SparkSession.builder.getOrCreate()
logger = glue_context.get_logger()
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

job_run_id = args['JOB_RUN_ID'] # Get the job run id for logging purposes

source_catalog_database = get_glue_env_var('source_data_database', '')
s3_ingestion_bucket_target = get_glue_env_var('s3_ingestion_bucket_target', '')
s3_ingestion_details_target = get_glue_env_var('s3_ingestion_details_target', '')
table_filter_expression = get_glue_env_var('table_filter_expression')

glue_client = boto3.client('glue')

database_tables = get_all_database_tables(glue_client, source_catalog_database, table_filter_expression)
logger.info(f"Number of tables to copy: {len(database_tables)}")

table_ingestion_details = []
num_copied_tables = 0

for table in database_tables:
    start = time.time()
    run_start_time = datetime.now() # Get the start time of the run for logging purposes
    logger.info(f"Reading in table: {table}, preparing to write table to s3. Timer started")
    try:
        source_ddf = glue_context.create_dynamic_frame.from_catalog(
            database=source_catalog_database,
            table_name=table,
            transformation_ctx=f"{table}_source_data"
        )

        data_frame = source_ddf.toDF()
        data_frame = data_frame.na.drop('all') # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
        row_count = data_frame.count()  # Capture row count of the DataFrame for logging purposes
        data_frame_with_import_columns = add_import_time_columns(data_frame)

        dynamic_frame_to_write = DynamicFrame.fromDF(data_frame_with_import_columns, glue_context, f"{table}_output_data")

        target_ddf = glue_context.write_dynamic_frame.from_options(
            frame=dynamic_frame_to_write,
            connection_type="s3",
            format="parquet",
            connection_options={
                "path": s3_ingestion_bucket_target + "/" + table + "/",
                "partitionKeys": PARTITION_KEYS
            },
            transformation_ctx=f"{table}_output_data"
        )

        end = time.time()
        minutes_taken = int((end - start)/60)
        logger.info(f"Finished writing table: {table} to s3. Time taken: {minutes_taken} mins.")
        num_copied_tables += 1
        logger.info(f'Copied: {num_copied_tables} tables')
        table_ingestion_details = update_table_ingestion_details(table_ingestion_details=table_ingestion_details,
                                                                 table_name=table,
                                                                 minutes_taken=minutes_taken,
                                                                 error='False',
                                                                 error_details='None',
                                                                 run_datetime=run_start_time,
                                                                 row_count=row_count,
                                                                 run_id=job_run_id)

    except Exception as e:
        logger.info(f"Failed to ingest table: {table}, error: {e}")
        table_ingestion_details = update_table_ingestion_details(table_ingestion_details=table_ingestion_details,
                                                                 table_name=table, 
                                                                 minutes_taken=0, 
                                                                 error='True', 
                                                                 error_details=str(e),
                                                                 run_datetime=run_start_time, 
                                                                 row_count=0, 
                                                                 run_id=job_run_id)

table_ingestion_details_df = spark_session.createDataFrame([Row(**i) for i in table_ingestion_details])
table_ingestion_details_ddf = DynamicFrame.fromDF(table_ingestion_details_df, glue_context, "table_ingestion_details")

target_ddf = glue_context.write_dynamic_frame.from_options(
    frame=table_ingestion_details_ddf,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": s3_ingestion_details_target
    },
    transformation_ctx=f"{source_catalog_database}_ingestion_details",
)

job.commit()