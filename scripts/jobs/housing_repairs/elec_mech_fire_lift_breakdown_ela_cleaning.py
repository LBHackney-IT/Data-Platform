import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from awsglue.dynamicframe import DynamicFrame
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

df2 = df2.withColumn('data_source', F.lit(
    'ElecMechFire - Lift Breakdown - ELA'))

df2 = df2.withColumn('date', F.to_date('date', "dd/MM/yyyy"))

# rename column names to reflect harmonised column names

df2 = df2.withColumn('datetime_raised', F.to_timestamp(
    'date', 'MM/dd/yy HH:mm:ss'))

df2 = df2.withColumnRenamed('requested_by', 'operative') \
    .withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('contractor_s_own_ref_no', 'contractor_ref')

df2 = map_repair_priority(df2, 'work_priority_description', 'work_priority_priority_code')

df2 = df2.select("data_source", "datetime_raised",
                 "operative", "property_address", "work_priority_description",
                 "work_priority_priority_code",
                 "temp_order_number_full", "contractor_ref",
                 "work_priority_priority_code",
                 "import_datetime", "import_timestamp", "import_year",
                 "import_month", "import_day", "import_date",
                 )

cleanedDataframe = DynamicFrame.fromDF(df2, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": cleaned_repairs_s3_bucket_target, "partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")
job.commit()
