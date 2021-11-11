import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import SQLContext

from jobs.helpers.helpers import get_glue_env_var, add_import_time_columns, clean_column_names, PARTITION_KEYS

s3_bucket_source = get_glue_env_var('s3_bucket_source', '')
s3_bucket_target = get_glue_env_var('s3_bucket_target', '')
header_row_number = get_glue_env_var('header_row_number', 0)
worksheet_name = get_glue_env_var('worksheet_name', '')

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

sqlContext = SQLContext(sc)

df = sqlContext.read.format("com.crealytics.spark.excel") \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .option("dataAddress", f'\'{worksheet_name}\'!A{int(header_row_number)}') \
    .load(s3_bucket_source)

df = clean_column_names(df)

df = df.na.drop('all') # Drop all rows where all values are null NOTE: must be done before add_import_time_columns
df = add_import_time_columns(df)

frame = DynamicFrame.fromDF(df, glueContext, "DataFrame")

parquet_data = glueContext.write_dynamic_frame.from_options(
    frame=frame,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": s3_bucket_target,
        "partitionKeys": PARTITION_KEYS
    },
    transformation_ctx="parquet_data"
)

job.commit()
