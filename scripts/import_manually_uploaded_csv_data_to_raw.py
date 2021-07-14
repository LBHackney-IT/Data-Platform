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

from helpers import get_glue_env_var, add_import_time_columns, get_s3_subfolders, PARTITION_KEYS

s3_client = boto3.client('s3')
sc = SparkContext()
glue_context = GlueContext(sc)

now = datetime.now()
logger = glue_context.get_logger()

def remove_empty_columns(data_frame):
    return data_frame.drop('')

def add_import_job_columns(data_frame):
    # f.input_file_name returns path so must extract filename between final '/' and subsequent '.'
    ## TESTING: TRY DIFFERENT VERSIONS >>> ##
    # ORIGINAL FAILED>> columns_added = data_frame.withColumn('import_filename', f.lit(('/'+f.input_file_name()+'.').split('/')[-1].split('.')[0]))
    # FAILED using regular python string manipulation>> columns_added = data_frame.withColumn('import_filename', ('/'+f.input_file_name()+'.').split('/')[-1].split('.')[0])
    # FAILED>> columns_added = data_frame.withColumn('import_filename', ('/'+str(f.input_file_name())+'.').split('/')[-1].split('.')[0])
    # THE FOLLOWING LINE allowed the job to run succesfully BUT what did it output in the parquets? Did it actually output a column containing the filename or path or do something else or fail even? >>>
    columns_added = data_frame.withColumn('import_pathname', f.input_file_name())
        # BUT THESE NEXT TWO TESTS FAILED. Trying to manipulate columns like a string looks tricky. Do f.split and f.concat methods work? Can i even access elements after f.split in this way? More to go and learn! >>>
        # .withColumn('import_filename', ('import_filename', f.split(f.split(f.concat('/',f.input_file_name(),'.'),'/')[-1],'.')[0]))
        # .withColumn('import_filename', ('import_filename', f.lit(f.split(f.split(f.concat('/',f.input_file_name(),'.'),'/')[-1],'.')[0])))
    return columns_added

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
  logger.info("Using Columns: " + str(data_frame.columns))
  data_frame = add_import_time_columns(data_frame)
  data_frame = add_import_job_columns(data_frame)

  data_output = DynamicFrame.fromDF(data_frame, glue_context, "cedar_data")

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
