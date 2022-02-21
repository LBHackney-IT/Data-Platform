import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.job import Job

from helpers.helpers import get_glue_env_var

args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args['JOB_NAME'], args)

source_catalog_database = get_glue_env_var('source_data_database', '')
source_catalog_table    = get_glue_env_var('source_data_catalogue_table', '')
s3_bucket_target = get_glue_env_var('s3_target', '')

source_ddf = glue_context.create_dynamic_frame.from_catalog(
    database=source_catalog_database,
    table_name=source_catalog_table,
    transformation_ctx="parquetData",
)

target_ddf = glue_context.write_dynamic_frame.from_options(
    frame=source_ddf,
    connection_type="s3",
    format="parquet",
    connection_options={
        "path": s3_bucket_target
    },
    transformation_ctx="parquetData",
)

job.commit()