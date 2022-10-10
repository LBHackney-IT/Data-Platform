import sys

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
import pyspark.sql.functions as F
from pyspark.sql.types import StringType
from awsglue.dynamicframe import DynamicFrame

from scripts.helpers.helpers import get_glue_env_var, get_latest_partitions, PARTITION_KEYS
from scripts.helpers.repairs import map_repair_priority, clean_column_names

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

source_catalog_database = get_glue_env_var('source_catalog_database', '')
source_catalog_table = get_glue_env_var('source_catalog_table', '')
cleaned_repairs_s3_bucket_target = get_glue_env_var('cleaned_repairs_s3_bucket_target', '')

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

df3 = df3.withColumn('datetime_raised', F.to_timestamp('date', 'yyyy-MM-dd'))

df3 = df3.withColumnRenamed('requested_by', 'operative') \
    .withColumnRenamed('address', 'property_address') \
    .withColumnRenamed('description', 'description_of_work') \
    .withColumnRenamed('priority_code', 'work_priority_description') \
    .withColumnRenamed('temp_order_number', 'temp_order_number_full') \
    .withColumnRenamed('cost_code', 'budget_code')\
    .withColumnRenamed('total_invoiced', 'order_value')\
    .withColumnRenamed('works_status_comments', 'order_status')\
    .withColumnRenamed('contractor_s_own_ref_no', 'contractor_ref')

df3 = df3.withColumn('order_value', df3['order_value'].cast(StringType()))

columns = [\
    'datetime_raised',\
    'operative',\
    'property_address',\
    'description_of_work',\
    'work_priority_description',\
    'temp_order_number_full',\
    'budget_code',\
    'order_value',\
    'order_status',\
    'contractor_ref',\
    'raised_value'\
]

df3 = df3.select(*columns, 'import_datetime', 'import_timestamp', 'import_year', 'import_month', 'import_day', 'import_date')

df3 = map_repair_priority(df3, 'work_priority_description', 'work_priority_priority_code')

df3 = df3.withColumn('data_source', F.lit('ElecMechFire - Electric Heating'))

cleanedDataframe = DynamicFrame.fromDF(df3, glueContext, "cleanedDataframe")
parquetData = glueContext.write_dynamic_frame.from_options(
    frame=cleanedDataframe,
    connection_type="s3",
    format="parquet",
    connection_options={"path": cleaned_repairs_s3_bucket_target,"partitionKeys": PARTITION_KEYS},
    transformation_ctx="parquetData")

job.commit()
