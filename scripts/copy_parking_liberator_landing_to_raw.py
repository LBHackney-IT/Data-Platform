import boto3
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

from helpers import get_glue_env_var, add_timestamp_column, PARTITION_KEYS

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

glue_client = boto3.client('glue')
database_name_source = get_glue_env_var("glue_database_name_source")
database_name_target = get_glue_env_var("glue_database_name_target")
bucket_target = get_glue_env_var("s3_bucket_target")
prefix = get_glue_env_var("s3_prefix")
logger = glue_context.get_logger()

for table in glue_client.get_tables(DatabaseName=database_name_source)['TableList']:
  logger.info(f"Starting copying table {database_name_source}{table['Name']}")
  table_dynamic_frame = glue_context.create_dynamic_frame.from_catalog(
      name_space = database_name_source,
      table_name = table['Name'],
      transformation_ctx = "data_source" + table['Name']
  )

  table_with_timestamp = add_timestamp_column(table_dynamic_frame.toDF())

  data_sink = glue_context.getSink(
    path = "s3://" + bucket_target + "/" + prefix + table['Name'] + "/",
    connection_type = "s3",
    updateBehavior = "UPDATE_IN_DATABASE",
    partitionKeys = PARTITION_KEYS,
    enableUpdateCatalog = True,
    transformation_ctx = "data_sink" + table['Name']
  )
  data_sink.setCatalogInfo(
    catalogDatabase = database_name_target,
    catalogTableName = table['Name']
  )
  data_sink.setFormat("glueparquet")
  data_sink.writeFrame(DynamicFrame.fromDF(table_with_timestamp, glue_context, "result_dataframe"))
  logger.info(f"Finished copying table {database_name_source}{table['Name']}")

job.commit()
