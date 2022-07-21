import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.types import StringType

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import map_repair_priority, clean_column_names

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
    'raised_value',
    'total_invoiced',
    'cost_code',
    'contractor_s_own_ref_no',
    'new_uhw_number',
    'requested_by',
    'works_status_comments',
    'import_year',
    'import_month',
    'import_day',
    'import_date',
    'import_datetime',
    'import_timestamp'
]]

# convert date column to datetime format
df2 = df2.withColumn('date', F.to_timestamp('date', 'yyyy-MM-dd'))

df2 = df2.withColumn('data_source', F.lit('ElecMechFire - Electrical Supplies'))

# rename column names to reflect harmonised column names
df2 = df2.withColumnRenamed('requested_by', 'operative') \
    .withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('cost_code', 'budget_code')\
    .withColumnRenamed('total_invoiced', 'order_value')\
    .withColumnRenamed('works_status_comments', 'order_status')\
    .withColumnRenamed('contractor_s_own_ref_no', 'contractor_ref')\
    .withColumnRenamed('date', 'datetime_raised')

df2 = df2.withColumn('order_value', df2['order_value'].cast(StringType()))

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target,"partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()