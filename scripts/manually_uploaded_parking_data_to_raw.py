import sys
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import functions as f
from awsglue.dynamicframe import DynamicFrame

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
      .withColumn('import_timestamp', f.lit(str(now.timestamp())))\
      .withColumn('import_year', f.lit(str(now.year)))\
      .withColumn('import_month', f.lit(str(now.month).zfill(2)))\
      .withColumn('import_day', f.lit(str(now.day).zfill(2)))
    return columns_added

def data_source_landing_to_raw(bucketSource, bucketTarget, object_path, glue_context):
  data_source = glue_context.create_dynamic_frame.from_options(
    format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"separator":","},
    connection_type = "s3",
    format = "csv",
    connection_options = {"paths": [bucketSource + "/" + object_path]},
    transformation_ctx = "data_source"
  )
  logger.info("Retrieved data source from s3 path {bucketSource}/{object_path}")

  logger.info("Converted into data frame")
  data_frame = data_source.toDF()
  data_frame = remove_empty_columns(data_frame)
  logger.info("Using Columns:")
  logger.info(data_frame.columns)
  data_frame = add_import_time_columns(data_frame)

  data_output = DynamicFrame.fromDF(data_frame, glue_context, "cedar_data")

  logger.info("Converted back into dynamic frame. Writing to s3...")

  glue_context.write_dynamic_frame.from_options(frame = data_output,
    connection_type = "s3",
    format = "parquet",
    connection_options = {"path": bucketTarget + "/" + object_path, "partitionKeys": ["import_year" ,"import_month" ,"import_day"]},
    transformation_ctx = "data_sink"
  )
  logger.info("Finished writing to s3 at path {bucketTarget}/{object_path}")

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

job = Job(glue_context)
job.init(args['JOB_NAME'], args)

s3BucketTarget = get_glue_env_var('s3_bucket_target', '')
s3BucketSource = get_glue_env_var('s3_bucket_source', '')


logger.info("Starting parking/manual-cedar/markets-expenditure/")
data_source_landing_to_raw(s3BucketTarget, s3BucketSource, "parking/manual-cedar/markets-expenditure/", glue_context)

logger.info("Starting parking/manual-cedar/markets-income/")
data_source_landing_to_raw(s3BucketTarget, s3BucketSource, "parking/manual-cedar/markets-income/", glue_context)

job.commit()