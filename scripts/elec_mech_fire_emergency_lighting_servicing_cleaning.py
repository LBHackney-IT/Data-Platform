import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
import re
from helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from repairs_cleaning_helpers import udf_map_repair_priority, clean_column_names

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var(
    'cleaned_repairs_s3_bucket_target', '')

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
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

df3 = df2
df3 = df3.withColumn('date', F.to_date('date', "yyyy-MM-dd"))
df3 = df3.withColumn('data_source', F.lit('ElecMechFire - Emergency Lighting Service'))

# rename column names to reflect harmonised column names
df3 = df3.withColumnRenamed('date', 'datetime_raised') \
    .withColumnRenamed('requested_by', 'operative') \
    .withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('cost', 'order_value')\
    .withColumnRenamed('status_of_completed_y_n', 'order_status')


# apply function
df3 = df3.withColumn('work_priority_priority_code', udf_map_repair_priority('work_priority_description'))
df3 = df3.replace('nan', None)

# only keep relevant columns
df3 = df3[[
    'datetime_raised',
    'operative',
    'property_address',
    'description_of_work',
    'work_priority_description',
    'temp_order_number_full',
    'order_value',
    'order_status',
    'data_source',
    'import_datetime',
    'import_timestamp',
    'import_year',
    'import_month',
    'import_day',
    'import_date'
]]

cleanedDataframe = DynamicFrame.fromDF(df3, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target,"partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()