import sys

from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import trim, when, trim
import pyspark.sql.functions as F
from pyspark.sql.functions import *
from pyspark.sql.types import StringType


from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import map_repair_priority


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
df = get_latest_partitions(df)

# drop empty rows
df2 = df.filter(df.address != 'nan')

logger.info('convert date columns to datetime / date field types')
df2 = df2.withColumn('date', F.to_timestamp('date', 'dd.MM.yy'))
df2 = df2.withColumn('date_completed', F.regexp_replace('date_completed', r'^[A-Za-z\s]*', ''))
df2 = df2.withColumn('date_completed', F.to_timestamp('date_completed', "dd/MM/yyyy"))
# keep selected columns
df2 = df2[['address',
           'description',
           'date',
           'temp_order_number',
           'priority_code',
           'sor',
           'cost',
           'subjective',
           'contractor_s_own_ref_no',
           'contractor_job_status_complete_or_in_progress',
           'date_completed',
           'new_uhw_number',
           'requested_by',
           'import_datetime',
           'import_timestamp',
           'import_year',
           'import_month',
           'import_day',
           'import_date']]

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

df2 = df2.withColumn('order_value', df2['order_value'].cast(StringType()))
# remove any spaces from 'work_priority_description' column so that values can be mapped where applicable
df2 = df2.withColumn('work_priority_description', trim(df2.work_priority_description))

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()
