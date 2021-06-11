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

s3_client = boto3.client('s3')
sc = SparkContext()
glue_context = GlueContext(sc)

now = datetime.now()
logger = glue_context.get_logger()

def get_glue_env_var(key, default="none"):
    if f'--{key}' in sys.argv:
        return getResolvedOptions(sys.argv, [key])[key]
    else:
        return default

def remove_empty_columns(data_frame):
    return data_frame.drop('')

def add_import_time_columns(data_frame):
    columns_added = data_frame.withColumn('import_date', f.current_timestamp())\
      .withColumn('import_timestamp', f.lit(now.timestamp()))\
      .withColumn('import_year', f.lit(str(now.year)))\
      .withColumn('import_month', f.lit(str(now.month).zfill(2)))\
      .withColumn('import_day', f.lit(str(now.day).zfill(2)))
    return columns_added

def data_source_landing_to_raw(bucket_source, bucket_target, key, glue_context):
  data_source = glue_context.create_dynamic_frame.from_options(
    format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"separator":","},
    connection_type = "s3",
    format = "csv",
    connection_options = {"paths": [bucket_source + "/" + key]},
    transformation_ctx = "data_source"
  )
  logger.info(f"Retrieved data source from s3 path {bucket_source}/{key}")

  data_frame = remove_empty_columns(data_source.toDF())
  logger.info("Using Columns: " + str(data_frame.columns))
  data_frame = add_import_time_columns(data_frame)

  data_output = DynamicFrame.fromDF(data_frame, glue_context, "cedar_data")

  logger.info(f"Writing to s3 path {bucket_target}/{key}")

  glue_context.write_dynamic_frame.from_options(frame = data_output,
    connection_type = "s3",
    format = "parquet",
    connection_options = {"path": bucket_target + "/" + key, "partitionKeys": ["import_year" ,"import_month" ,"import_day"]},
    transformation_ctx = "data_sink"
  )

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
s3_bucket_source = get_glue_env_var('s3_bucket_source', '')

folders = s3_client.list_objects_v2(
    Bucket=s3_bucket_source,
    Delimiter='/',
    Prefix='parking/manual/'
)

for folder in folders['CommonPrefixes']:
  key = folder['Prefix']

  logger.info(f"Starting {key}")
  data_source_landing_to_raw("s3://" + s3_bucket_source, "s3://" + s3_bucket_target, key, glue_context)
  logger.info(f"Finished {key}")

job.commit()
