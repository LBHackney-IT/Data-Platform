import re
import sys

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.ml import Pipeline
from pyspark.ml.feature import RegexTokenizer, NGram, HashingTF, MinHashLSH
from pyspark.sql import types as t
from pyspark.sql.window import Window
from pyspark.sql.functions import rank, col, trim, when, max, trim
import pyspark.sql.functions as F
from pyspark.sql.types import StringType, TimestampType

from helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from repairs_cleaning_helpers import udf_map_repair_priority


args = getResolvedOptions(sys.argv, ['JOB_NAME'])

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table    = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var('cleaned_repairs_s3_bucket_target', '')

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
df = getLatestPartitions(df)

# drop empty rows
df2 = df.filter(df.address != 'nan')

logger.info('convert date columns to datetime / date field types')
df2 = df2.withColumn('date', F.to_timestamp('date', 'dd.MM.yy'))

# drop empty and unused columns
df2 = df2.drop('unnamed:_13',
               'unnamed:_14',
               'unnamed:_15',
               'unnamed:_16',
               'unnamed:_17',
               'unnamed:_18',
               'unnamed:_19',
               'unnamed:_20',
               'unnamed:_21',
               'unnamed:_22',
               'unnamed:_23',
               'unnamed:_24',
               'unnamed:_25',
               'unnamed:_26',
               'unnamed:_27',
               'unnamed:_28',
               'unnamed:_29',
               'unnamed:_30',
               'unnamed:_31'
               )

# add new data source column to specify which repairs sheet the repair came from
df2 = df2.withColumn('data_source', F.lit('ElecMechFire - Fire Alarm AOV'))

# rename column names
df2 = df2.withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('date', 'datetime_raised') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('cost', 'order_value') \
    .withColumnRenamed('subjective', 'budget_code') \
    .withColumnRenamed('contractor_s_own_ref_no', 'contractor_ref') \
    .withColumnRenamed('contractor_job_status_complete_or_in_progress', 'order_status') \
    .withColumnRenamed('date_completed', 'completed_date') \
    .withColumnRenamed('requested_by', 'operative')

# remove any spaces from 'work_priority_description' column so that values can be mapped where applicable
df2 = df2.withColumn('work_priority_description', trim(df2.work_priority_description))

# apply function
df2 = df2.withColumn('work_priority_priority_code', udf_map_repair_priority('work_priority_description'))

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()