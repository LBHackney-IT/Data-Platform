import sys

import pyspark.sql.functions as F
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, max
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import map_repair_priority, clean_column_names

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var(
    'cleaned_repairs_s3_bucket_target', '')

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

source_data = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table,
)

df = source_data.toDF()

df = get_latest_partitions(df)
df2 = clean_column_names(df)

# rename column names to reflect harmonised column banes
logger.info('convert timestamp and date columns to datetime / date field types')
df2 = df2.withColumn('timestamp', F.to_timestamp(
    "timestamp", "dd/MM/yyyy HH:mm:ss"))
df2 = df2.withColumn('data_source', F.lit('Purdy Cleaning'))
df2 = df2.withColumn('date_temp_order_reference', F.to_date(
    'date_temp_order_reference', "dd/MM/yyyy HH:mm:ss"))

df2 = df2.withColumn('date_completed', F.to_timestamp(
    'date_completed', "dd/MM/yyyy"))

df2 = df2.withColumnRenamed('notes_and_information', 'notes') \
    .withColumnRenamed('Priority', 'work_priority_description') \
    .withColumnRenamed('email_address', 'email_staff') \
    .withColumnRenamed('temporary_order_number', 'temp_order_number_full') \
    .withColumnRenamed('date_temp_order_reference', 'temp_order_number_date') \
    .withColumnRenamed('time_temp_order_reference', 'temp_order_number_time') \
    .withColumnRenamed('date_completed', 'completed_date') \
    .withColumnRenamed('timestamp', 'datetime_raised')

# drop unnecessary columns
df2 = df2.drop('column11')
df2 = df2.drop('additional_notes')

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()
