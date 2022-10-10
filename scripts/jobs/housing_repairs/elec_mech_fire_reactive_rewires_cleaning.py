import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from pyspark.sql.functions import *
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.types import StringType
from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import clean_column_names, map_repair_priority

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

# only keep relevant columns
df2 = df2[[
    'address',
    'description',
    'date',
    'temp_order_number',
    'priority_code',
    'contractor_s_own_ref_no',
    'new_uhw_number',
    'cost_of_repairs_work',
    'status_of_completed_y_n',
    'requested_by',
    'import_year',
    'import_month',
    'import_day',
    'import_date',
    'import_datetime',
    'import_timestamp'
]]

# convert date column to datetime format
df2 = df2.withColumn('date', F.to_timestamp('date', 'yyyy-MM-dd')).withColumnRenamed('date', 'datetime_raised')

df2 = df2.withColumn('status_of_completed_y_n', when(df2['status_of_completed_y_n']=='Y', 'Completed').otherwise(''))\
    .withColumnRenamed('status_of_completed_y_n', 'order_status')

df2 = df2.withColumn('data_source', F.lit('ElecMechFire - Reactive Rewires'))

# rename column names to reflect harmonised column names
df2 = df2.withColumnRenamed('requested_by', 'operative') \
    .withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('cost_of_repairs_work', 'order_value')\
    .withColumnRenamed('contractor_s_own_ref_no', 'contractor_ref')

df2 = df2.withColumn('order_value', df2['order_value'].cast(StringType()))
df2 = df2.withColumn('temp_order_number_full', df2['temp_order_number_full'].cast(StringType()))

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target,"partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()
