import boto3
import sys
import re
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

from scripts.helpers.helpers import get_glue_env_var, add_timestamp_column, PARTITION_KEYS

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)

try:
    job.init(args["JOB_NAME"] + args["BOOKMARK_CONTEXT"], args)
except Exception:
    job.init(args["JOB_NAME"], args)
    
glue_client = boto3.client('glue')
database_name_source = get_glue_env_var("glue_database_name_source")
database_name_target = get_glue_env_var("glue_database_name_target")
bucket_target = get_glue_env_var("s3_bucket_target")
prefix = get_glue_env_var("s3_prefix")
table_filter_expression = get_glue_env_var("table_filter_expression")
logger = glue_context.get_logger()

filtering_pattern = re.compile(table_filter_expression)
tables_to_copy = [table for table in glue_context.tableNames(dbName=database_name_source) if filtering_pattern.match(table)]
logger.info(f"Tables to copy: {tables_to_copy}")
logger.info(f"Number of tables to copy: {len(tables_to_copy)}")

for table_name in tables_to_copy:
  logger.info(f"Starting to copy table {database_name_source}.{table_name}")
  table_data_frame = glue_context.create_dynamic_frame.from_catalog(
      name_space = database_name_source,
      table_name = table_name,
      transformation_ctx = "data_source" + table_name,
      push_down_predicate = "import_date>=date_format(date_sub(current_date, 5), 'yyyyMMdd')"
  ).toDF()

  if(len(table_data_frame.columns) == 0):
    logger.info(f"Aborting copy of data for table {database_name_source}.{table_name}, as it has empty columns.")
    continue

  table_with_timestamp = add_timestamp_column(table_data_frame)

  data_sink = glue_context.getSink(
    path = "s3://" + bucket_target + "/" + prefix + table_name + "/",
    connection_type = "s3",
    updateBehavior = "UPDATE_IN_DATABASE",
    partitionKeys = PARTITION_KEYS,
    enableUpdateCatalog = True,
    transformation_ctx = "data_sink" + table_name
  )
  data_sink.setCatalogInfo(
    catalogDatabase = database_name_target,
    catalogTableName = table_name
  )
  data_sink.setFormat("glueparquet")
  data_sink.writeFrame(DynamicFrame.fromDF(table_with_timestamp, glue_context, "result_dataframe"))
  logger.info(f"Finished copying table {database_name_source}.{table_name}")

job.commit()
