import sys
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as f
from awsglue.dynamicframe import DynamicFrame
import boto3

from scripts.helpers.helpers import get_glue_env_var, add_import_time_columns, get_s3_subfolders, PARTITION_KEYS, clean_column_names

s3_client = boto3.client('s3')
sc = SparkContext()
glue_context = GlueContext(sc)

now = datetime.now()
logger = glue_context.get_logger()

def remove_empty_columns(data_frame):
    return data_frame.drop('')

def data_source_landing_to_raw(bucket_source, bucket_target, key, glue_context):
  data_source = glue_context.create_dynamic_frame.from_options(
    format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"separator":","},
    connection_type = "s3",
    format = "csv",
    connection_options = {"paths": [bucket_source + "/" + key]},
    transformation_ctx = "data_source_" + key
  )
  logger.info(f"Retrieved data source from s3 path {bucket_source}/{key}")

  data_frame = remove_empty_columns(data_source.toDF())
  data_frame = clean_column_names(data_frame)
  logger.info("Using Columns: " + str(data_frame.columns))
  data_frame = add_import_time_columns(data_frame)

  data_output = DynamicFrame.fromDF(data_frame, glue_context, "ringgo_data")

  logger.info(f"Writing to s3 path {bucket_target}/{key}")

  glue_context.write_dynamic_frame.from_options(frame = data_output,
    connection_type = "s3",
    format = "parquet",
    connection_options = {"path": bucket_target + "/" + key, "partitionKeys": PARTITION_KEYS},
    transformation_ctx = "data_sink_" + key
  )

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
s3_prefix = get_glue_env_var('s3_prefix', '')
s3_bucket_source = get_glue_env_var('s3_bucket_source', '')

for key in get_s3_subfolders(s3_client, s3_bucket_source, s3_prefix):
  logger.info(f"Starting {key}")
  data_source_landing_to_raw("s3://" + s3_bucket_source, "s3://" + s3_bucket_target, key, glue_context)
  logger.info(f"Finished {key}")

job.commit()
