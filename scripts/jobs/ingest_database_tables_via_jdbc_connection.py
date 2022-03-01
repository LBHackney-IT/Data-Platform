import sys
import boto3
import time
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from pyspark.sql import SparkSession, Row

from helpers.helpers import get_glue_env_var, get_all_database_tables, update_table_ingestion_details

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
spark_session = SparkSession.builder.getOrCreate()
logger = glue_context.get_logger()
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

source_catalog_database = get_glue_env_var('source_data_database', '')
s3_ingestion_bucket_target = get_glue_env_var('s3_ingestion_bucket_target', '')
s3_ingestion_details_target = get_glue_env_var('s3_ingestion_details_target', '')

glue_client = boto3.client('glue')

database_tables = get_all_database_tables(source_catalog_database, glue_client)
logger.info(f"Number of tables to copy: {len(database_tables)}")

table_ingestion_details = []
num_copied_tables = 0

for table in database_tables:
    start = time.time()
    logger.info(f"Reading in table: {table}, preparing to write table to s3. Timer started")
    try:
        source_ddf = glue_context.create_dynamic_frame.from_catalog(
            database=source_catalog_database,
            table_name=table,
            transformation_ctx="parquetData",
        )

        target_ddf = glue_context.write_dynamic_frame.from_options(
            frame=source_ddf,
            connection_type="s3",
            format="parquet",
            connection_options={
                "path": s3_ingestion_bucket_target + "/" + table + "/"
            },
            transformation_ctx="parquetData",
        )

        end = time.time()
        minutes_taken = int((end - start)/60)
        logger.info(f"Finished writing table: {table} to s3. Time taken: {minutes_taken} mins.")
        num_copied_tables += 1
        logger.info(f'Copied: {num_copied_tables} tables')
        update_table_ingestion_details(table_name=table, minutes_taken=minutes_taken, error='False', error_details='None')

    except Exception as e:
        logger.info(f"Failed to ingest table: {table}, error: {e}")
        update_table_ingestion_details(table_name=table, minutes_taken=0, error='True', error_details=e)

table_ingestion_details_df = spark_session.createDataFrame([Row(**i) for i in table_ingestion_details])
table_ingestion_details_ddf = DynamicFrame.fromDF(table_ingestion_details_df, glue_context, "table_ingestion_details")

target_ddf = glue_context.write_dynamic_frame.from_options(
    frame=table_ingestion_details_ddf,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": s3_ingestion_details_target
    },
    transformation_ctx="parquetData",
)

job.commit()