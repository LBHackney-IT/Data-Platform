import sys
import re

from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql.functions import rank, col, trim, when, max, trim
import pyspark.sql.functions as F
from pyspark.sql.types import StringType
from pyspark.sql.window import Window

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import clean_column_names, map_repair_priority

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

logger.info('Fetch Source Data')

source_data = glueContext.create_dynamic_frame.from_catalog(
    name_space=source_catalog_database,
    table_name=source_catalog_table
)

df = source_data.toDF()
df = get_latest_partitions(df)

# clean up column names, data types
df2 = clean_column_names(df)

logger.info('convert timestamp and date columns to datetime / date field types')
df2 = df2.withColumn('timestamp', F.to_timestamp(
    "timestamp", "dd/MM/yyyy HH:mm:ss"))

# add new data source column to specify which repairs sheet the repair came from
df2 = df2.withColumn('data_source', F.lit('Stannah'))

# rename column names
df2 = df2.withColumnRenamed('email_address', 'email_staff') \
    .withColumnRenamed('temporary_order_number', 'temp_order_number_full') \
    .withColumnRenamed('sors_frequent_use_only', 'sor') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('notes_and_information', 'notes') \
    .withColumnRenamed('value_costs', 'order_value') \
    .withColumnRenamed('timestamp', 'datetime_raised') 

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

# drop columns not needed
df2 = df2.drop(df2.column10)

# write to S3
cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()
