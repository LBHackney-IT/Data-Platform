import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, max
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
from helpers import get_glue_env_var, PARTITION_KEYS
from repairs_cleaning_helpers import udf_map_repair_priority, remove_multiple_and_trailing_underscores_and_lowercase


def getLatestPartitions(dfa):
    dfa = dfa.where(col('import_year') == dfa.select(
        max('import_year')).first()[0])
    dfa = dfa.where(col('import_month') == dfa.select(
        max('import_month')).first()[0])
    dfa = dfa.where(col('import_day') == dfa.select(
        max('import_day')).first()[0])
    return dfa


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

df = getLatestPartitions(df)
df2 = remove_multiple_and_trailing_underscores_and_lowercase(df)

# rename column names to reflect harmonised column banes
logger.info('convert timestamp and date columns to datetime / date field types')
df2 = df2.withColumn('timestamp', F.to_timestamp(
    "timestamp", "dd/MM/yyyy HH:mm:ss"))

df2 = df2.withColumnRenamed('notes_and_information', 'notes') \
    .withColumnRenamed('Priority', 'work_priority_description') \
    .withColumnRenamed('email_address', 'email_staff') \
    .withColumnRenamed('temporary_order_number', 'temp_order_number_full') \
    .withColumnRenamed('date_temp_order_reference', 'temp_order_number_date') \
    .withColumnRenamed('time_temp_order_reference', 'temp_order_number_time') \
    .withColumnRenamed('date_completed', 'completed_date') \

# drop unnecessary columns
df2 = df2.drop('column11')
df2 = df2.drop('additional_notes')

# apply function
df2 = df2.withColumn('work_priority_priority_code',
                     udf_map_repair_priority('work_priority_description'))

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()
